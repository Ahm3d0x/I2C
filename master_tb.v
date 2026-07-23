`timescale 1ns/1ps

module master_tb;
reg clk = 0;
reg rst;
reg        m_start_i;
reg        m_stop_i;
reg [6:0]  m_slv_add_i;
reg        m_w_r_i;
reg [7:0]  m_data_i;
reg        m_ack_i;
wire [7:0] m_data_o;
wire       m_busy_o;
wire       m_data_ready_o;
wire       m_error_o;
wire       SDA;
wire       SCL;



// master DUT for testing
master master_dut (
    .clk(clk),
    .rst(rst),
    .m_start_i(m_start_i),
    .m_stop_i(m_stop_i),
    .m_slv_add_i(m_slv_add_i),
    .m_w_r_i(m_w_r_i),
    .m_data_i(m_data_i),
    .m_ack_i(m_ack_i),
    .m_data_o(m_data_o),
    .m_busy_o(m_busy_o),
    .m_data_ready_o(m_data_ready_o),
    .m_error_o(m_error_o),
    .SDA(SDA),
    .SCL(SCL)
);

always #5 clk = ~clk;
pullup(SDA);



// slave control logic
reg       slave_drive;
reg       slave_bit;
reg       ack_addr_val = 0; // control the ack signal
reg       ack_data_val = 0; // the same
reg [7:0] read_slave_data;
assign SDA = (slave_drive && !slave_bit) ? 1'b0 : 1'bz; // slave_bit > 0 and z > 1 using open drain and pullup





always @(posedge clk or posedge rst) begin
    if (rst) begin
        slave_drive <= 0;
        slave_bit   <= 1;
    end else begin


        if (master_dut.state == 4) begin // send slave addr ack
            slave_drive <= 1'b1;
            slave_bit   <= ack_addr_val;


        end else if (master_dut.state == 7) begin //  slave send data on the SDA
            slave_drive <= 1'b1;
            slave_bit   <= read_slave_data[master_dut.counter];


        end else if (master_dut.state == 9 && m_w_r_i == 0) begin // send data ack after slave receive data
            slave_drive <= 1'b1;
            slave_bit   <= ack_data_val;

        end else begin // idle
            slave_drive <= 1'b0;
            slave_bit   <= 1'b1;
        end
    end
end

// Main Stimulus Sequence
initial begin
        $display("\n====================================================================================================================================");
        $display("# time : ns | state | SDA | SCL | Slave_Addr | R/W | Data_to_slave | Data_to_procesor | Busy | Ready | Error | Action");
        $display("========================================================================================================================================");
    
    rst          = 1;
    m_start_i    = 0;
    m_stop_i     = 0;
    m_w_r_i      = 0;
    m_ack_i      = 0;
    m_slv_add_i  = 7'b1010101;
    m_data_i     = 8'b11001010;
    ack_addr_val = 0;
    ack_data_val = 0;

    #20;
    rst = 0;
    #20;


    // TEST 1: WRITE
    $display("\n>>> TEST 1 START -----------------------------------------------.  <<<\n");

    @(posedge clk);
    m_start_i = 1;
    @(posedge clk);
    m_start_i = 0;

    // first Byte
    wait(master_dut.state == 10);
    m_data_i = 8'b10101111; // second byte
    m_stop_i = 0;           // keep transmitting

    // Second Byte
    wait(master_dut.state == 5); 
    m_stop_i = 1;           // send STOP after this byte

    // Wait until transaction fully completes and goes to idle
    wait(master_dut.state == 0); 
    #100;
    $display("\n>>> TEST 1 FINISHED.  <<<\n");
    $stop; // stop the case just for debugging and testing



    // TEST 2: READ
    $display("\n>>> TEST 2 START -----------------------------------------------.  <<<\n");
    read_slave_data = 8'b10110011; // the data that the slave will send
    m_w_r_i   = 1; 
    m_stop_i  = 1; // will read just one byte and stop
    m_ack_i   = 0; 
    @(posedge clk);
    m_start_i = 1;
    @(posedge clk);
    m_start_i = 0;
    wait(master_dut.state == 7); // just to out from idle
    wait(master_dut.state == 0); // back to idle
    #100;
    $display("\n>>> TEST 2 FINISHED.  <<<\n");
    $stop; // stop the case just for debugging and testing



    // TEST 3: NACK
    $display("\n>>> TEST 3 START -----------------------------------------------.  <<<\n");
    ack_addr_val = 1; // will send NACK and error flag make the state back to resend the data
    m_w_r_i      = 0; //write
    m_stop_i     = 1; // will read just one byte and stop
    @(posedge clk);
    m_start_i = 1;
    @(posedge clk);
    m_start_i = 0;
    
    wait(m_error_o == 1'b1); // wait for the NACK flag
    #50;
    ack_addr_val = 0; // will send ACK
    wait(master_dut.state == 0); // back to idle no error
$display("\n>>> TEST 3 FINISHED.  <<<\n");
    $stop; // stop the case just for debugging and testing




// TEST 4: read more than one byte
    $display("\n>>> TEST 4 START -----------------------------------------------.  <<<\n");
read_slave_data = 8'b11110000; // First byte to send from slave 
    m_w_r_i   = 1;
    m_stop_i  = 0; // Don't stop yet
    m_ack_i   = 0; // Send ACK for first byte
    @(posedge clk);
    m_start_i = 1;
    @(posedge clk);
    m_start_i = 0;

    wait(m_data_ready_o == 1'b1); // First byte received and master ready to give the data to the processor

    read_slave_data = 8'b00001111; // Second byte from slave
    m_ack_i  = 1; // NACK for second byte
    m_stop_i = 1; // Send STOP after second byte without retransmission
    wait(master_dut.state == 0);

    #100;
$display("\n>>> TEST 4 FINISHED.  <<<\n");
    $stop; // stop the case just for debugging and testing


// TEST 5: DATA NACK DURING WRITE
$display("\n>>> TEST 5 START -----------------------------------------------.  <<<\n");

    ack_addr_val = 0; // Address ACK PASS
    ack_data_val = 1; // Force Data NACK
    m_w_r_i = 0;
    m_data_i = 8'b10101010;
    m_stop_i = 1;
    @(posedge clk);
    m_start_i = 1;
    @(posedge clk);
    m_start_i = 0;
    wait(m_error_o == 1'b1); // Master detects Data NACK
    #50; ack_data_val = 0; // Clear NACK

    wait(master_dut.state == 0);

    #100;

    $display("=========================================================================================================================================\n");
    #200;
    $stop;
end



reg [3:0] prev_state;

always @(posedge clk or posedge rst) begin
      if (rst) 
          prev_state <= 0;
      else 
          prev_state <= master_dut.state;
  end

//  monitor at all states
always @(posedge master_dut.pos_clk or posedge master_dut.neg_clk) begin
    case(master_dut.state)
        0: if (master_dut.pos_clk && prev_state != 0) // print S0 when entering IDLE not all the time
           $display("# time : %0d | S0    |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | TRANSITION: BUS IDLE", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o);

        1: if (master_dut.pos_clk) // start tansition at scl high
           $display("# time : %0d | S1    |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | EVENT: START", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o);

        2: $display("# time : %0d | S2    |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | SEND ADDR[%0d]=%b", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o, master_dut.counter, master_dut.address_rw[master_dut.counter]);

        3: if (master_dut.neg_clk)  //مش قادر اكمل تعليق 👾
           $display("# time : %0d | S3    |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | RELEASE SDA FOR ACK", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o);
        
        4: if (master_dut.pos_clk) 
           $display("# time : %0d | S4    |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | ADDR ACK CHECK: %s", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o, (SDA == 0) ? "PASS (ACK)" : "FAIL (NACK)");

        5: $display("# time : %0d | S5    |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | WRITE DATA bit[%0d]=%b", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o, master_dut.counter, master_dut.data_in[master_dut.counter]);

        6: if (master_dut.neg_clk)
           $display("# time : %0d | S6    |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | RELEASE SDA FOR DATA ACK", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o);

        7: if (master_dut.pos_clk)
           $display("# time : %0d | S7    |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | READ DATA bit[%0d]=%b", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o, master_dut.counter, SDA);

        8: if (master_dut.neg_clk)
           $display("# time : %0d | S8    |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | READ COMPLETE: Latching Output", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o);

        9: if (master_dut.pos_clk)
           $display("# time : %0d | S9    |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | DATA ACK CHECK: %s", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o, (SDA == 0) ? "PASS (ACK)" : "FAIL (NACK)");

        10: if (master_dut.pos_clk)
           $display("# time : %0d | S10   |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | NEXT BYTE SETUP", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o);

        11: if (master_dut.pos_clk)
           $display("# time : %0d | S11   |  %b  |  %b  |   %b  |  %b  |  %b  |   %b  |   %b  |   %b   |   %b   | EVENT: STOP CONDITION (SDA: 0->1)", 
                    $time, SDA, SCL, m_slv_add_i, m_w_r_i, master_dut.data_in, m_data_o, m_busy_o, m_data_ready_o, m_error_o);
    endcase
end

endmodule