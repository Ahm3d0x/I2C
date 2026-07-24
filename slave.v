module slave (
    input clk,
    input rst,

    // connect to master bus
    inout SDA,
    input SCL,

    // connect to memory
    output reg [7:0] data_o, // memory out bus
    input      [7:0] data_i, // mamory in bus
    output reg  we_i
);

    parameter [6:0] slave_addr = 7'b1010101; // slave address
    // bus output
    reg sda_out;
    assign SDA = (!sda_out) ? 1'b0 : 1'bz;





    // detect start and stop conditions on sda/scl
    reg sda_q;
    reg scl_q;
    // to store sda and scl prevuios value using none blocking assignment
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sda_q <= 1'b1;
            scl_q <= 1'b1;
        end else begin
            sda_q <= SDA;
            scl_q <= SCL;
        end
    end
    wire start_cond = (scl_q && SDA == 0 && sda_q == 1); // high scl sda from high to low
    wire stop_cond  = (scl_q && SDA == 1 && sda_q == 0); // high scl sda from low to high
    // detect scl edges
    wire scl_pos = (SCL == 1 && scl_q == 0); // high scl from low to high
    wire scl_neg = (SCL == 0 && scl_q == 1); // high scl from high to low







// slave states
    parameter s0 = 3'b000, s1 = 3'b001, s2 = 3'b010, s3 = 3'b011, s4 = 3'b100, s5 = 3'b101, s6 = 3'b110;

reg [2:0] state;
reg [2:0] counter;
reg [7:0] addr_reg;
reg [7:0] data_in;  // received data from master
reg [7:0] data_out; // transmit data to master
reg rw_bit;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= s0;
            sda_out  <= 1'b1;
            we_i     <= 1'b0;
            data_o   <= 8'b0000000;
            data_in  <= 8'b0000000;
            data_out <= 8'b0000000;
            counter  <= 3'b111;
        end else begin
            we_i <= 1'b0;
            // master control slave stop and start
            if (stop_cond) begin
                state   <= s0;
                sda_out <= 1'b1;
            end else if (start_cond) begin
                state   <= s1;
                counter <= 3'b111;
                sda_out <= 1'b1;
            end else begin

                case (state)


                    s0: begin // idle
                        sda_out <= 1'b1;
                        counter <= 3'b111;
                    end

                    s1: begin // lisen to sda to receive addr
                        if (scl_pos) begin
                            addr_reg[counter] <= SDA;
                            if (counter != 0) begin
                                counter <= counter - 1'b1;
                            end else begin
                                state <= s2;
                            end
                        end
                    end

                    s2: begin // check received addr and send response
                        if (scl_neg) begin
                            if (addr_reg[7:1] == slave_addr) begin //1 to 7 is slave address 0 is r/w
                                sda_out <= 1'b0; // send ack
                                rw_bit  <= addr_reg[0];
                            end else begin
                                sda_out <= 1'b1; // send nack
                            end
                        end else if (scl_pos) begin
                            if (addr_reg[7:1] == slave_addr) begin
                                counter <= 3'b111;
                                if (addr_reg[0] == 1'b0) begin // route to write
                                    state <= s3; 
                                end else begin // route to read

                                    data_out <= data_i; // get data from memory bus
                                    state <= s5;
                                end
                            end else begin
                                state <= s0;
                            end
                        end
                    end

                    s3: begin // write_data
                        if (scl_pos) begin
                            data_in[counter] <= SDA; // receive siral data from master
                            if (counter != 0) begin
                                counter <= counter - 1'b1;
                            end else begin
                                state <= s4;
                            end
                        end
                    end

                    s4: begin // write_ack
                        if (scl_neg) begin
                            sda_out <= 1'b0;
                            we_i    <= 1'b1;    // enable mamory write
                            data_o  <= data_in; // send data to memory bus
                        end else if (scl_pos) begin
                            counter <= 3'b111;
                            state   <= s3;      // ready for next byte
                        end
                    end

                    s5: begin // read_data
                        if (scl_neg) begin
                            sda_out <= data_out[counter]; // drive bit
                            if (counter != 0) begin
                                counter <= counter - 1'b1;
                            end else begin
                                state <= s6;
                            end
                        end
                    end

                    s6: begin // read_ack from processor to master to slave
                        if (scl_neg) begin
                            sda_out <= 1'b1; // release bus for master ack
                        end else if (scl_pos) begin
                            if (SDA == 1'b0) begin // master sent ack
                                counter  <= 3'b111;
                                data_out <= data_i; // latch next byte
                                state    <= s5;
                            end else begin // master sent  stop nack
                                if (stop_cond) begin
                                    state <= s0;
                                end else begin // resend data
                                    counter <= 3'b111;
                                    state   <= s5;
                            end
                            end
                        end
                    end

                endcase
            end
            end
        end
endmodule