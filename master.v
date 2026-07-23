module master(
    // from processor
    input clk,
    input rst,
    input m_start_i,
    input m_stop_i,
    input [6:0] m_slv_add_i,
    input m_w_r_i,
    input [7:0] m_data_i,
    input m_ack_i,
    // to procesor
    output reg [7:0] m_data_o,
    output reg m_busy_o,
    output reg m_data_ready_o,
    output reg m_error_o,
    // to slave
    inout SDA,
    output SCL
);

//sda is bidirectional and open drain and scl is drive only by the master
reg sda_out;
wire pos_clk;
wire neg_clk;

assign SDA = (!sda_out)? 1'b0: 1'bz;
clk_DIVIDER clk_divider(.clk(clk), .rst(rst), .pos_clk(pos_clk), .neg_clk(neg_clk), .SCL(SCL));


parameter S0 = 4'b0000, S1 = 4'b0001, S2 = 4'b0010, S3 = 4'b0011, S4 = 4'b0100, S5 = 4'b0101, S6 = 4'b0110, S7 = 4'b0111, S8 = 4'b1000 , S9 = 4'b1001 , S10 = 4'b1010 ,S11 =4'b1011;
reg [3:0] state;
reg [2:0] counter;
reg [7:0] address_rw;
reg [7:0] data_in;
reg s_start = 1'b0;
reg s_stop = 1'b0;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        sda_out <= 1'b1;
        m_data_o <= 8'b00000000;
        m_busy_o <= 1'b0;
        m_data_ready_o <= 1'b0;
        m_error_o <= 1'b0;
        s_start <= 1'b0;
        s_stop <= 1'b0;
        state <= S0;
    end else begin
        case (state)
            S0: begin //idle
                sda_out <= 1'b1;
                m_data_o <= 8'b00000000;
                m_busy_o <= 1'b0;
                m_data_ready_o <= 1'b0;
                m_error_o <= 1'b0;
                s_start <= 1'b0;
                s_stop <= 1'b0;
                counter <= 3'b000;
                if (m_start_i) begin
                    state <= S1;    
                    m_busy_o <= 1'b1;
                end
            end
            S1: begin //start
                if (pos_clk) begin
                if (s_start == 1'b0) begin
                    sda_out <= 1'b0;
                    s_start <= 1'b1;
                end else begin
                    address_rw <= {m_slv_add_i, m_w_r_i};
                    data_in <= m_data_i;
                    counter <= 7;
                    state <= S2;
                end
            end
            end
            S2: begin //slave address + r/w
                if (neg_clk) begin
                    sda_out <= address_rw[counter];
                    if (counter != 0) begin
                        counter <= counter - 1'b1;
                    end else begin
                    state <= S3;
                    end
                end
            end

            S3: begin // SDA release after sending slave address 
                if (neg_clk) begin
                        sda_out <= 1'b1;
                        state <= S4;
                end
            end

            S4: begin // slave address ack
                if (pos_clk) begin
                    if (!SDA) begin
                        counter <= 7;
                        if (m_w_r_i == 0) begin
                            state <= S5;
                        end else begin
                            sda_out <= 1'b1;
                            state <= S7;
                        end
                    end else begin
                        m_error_o <= 1'b1;
                        counter <= 7;
                        state <= S2; //resend address
                    end
                end
            end

            // if w then send data
            S5: begin // serial data by master
                if (neg_clk) begin
                    sda_out <= data_in[counter];
                    if (counter != 0) begin
                        counter <= counter - 1'b1;
                    end else begin
                        state <= S6;
                    end
                end 
            end

            S6: begin // SDA release after sending data ack
                if (neg_clk) begin
                    sda_out <= 1'b1;
                    m_busy_o <= 1'b0;
                    state <= S9;
                end
            end

            // if r then recieve data
            S7: begin // serial data  by slave
                if (pos_clk) begin //open drain >> to give the slave the ability to drive sda
                    m_busy_o <= 1'b1;
                    data_in[counter] <= SDA;
                    if (counter != 0) begin
                        counter <= counter - 1'b1;
                    end else begin
                        state <= S8;
                    end
                end
            end

            // if data is  recived pass it to the processor
            S8: begin 
                if (neg_clk) begin
                    m_data_ready_o <= 1'b1;
                    m_data_o <= data_in;
                    if (m_w_r_i == 1'b1) begin
                        sda_out <= m_ack_i;
                    end 
                        state <= S9;
                    
                end
            end


            S9: begin // ACK/NACK after byte transmission
                if (pos_clk) begin
                    if (m_w_r_i == 1'b0) begin // WRITE MODE
                        if (SDA == 1'b0) begin 
                            m_error_o <= 1'b0;
                            if (m_stop_i == 1'b1) begin
                                state <= S11;
                            end else begin
                                state <= S10;
                            end
                        end else begin
                            counter   <= 7;
                            m_error_o <= 1'b1;
                            state <= S5; // Retry write
                        end
                    end else begin // READ MODE
                    
                        if (m_ack_i == 1'b0) begin // Master sends ACK
                            m_error_o <= 1'b0;
                            if (m_stop_i == 1'b1) begin
                                state <= S11;
                            end else begin
                                counter <= 7;
                                sda_out <= 1'b1;
                                state   <= S7; // Read next byte
                            end
                        end else begin // Master sends NACK
                            m_error_o <= 1'b0;
                            state <= S11;
                        end
                    end
                end
            end




            S10: begin
                if (m_stop_i == 1'b1) begin
                    state <= S11;
                end else begin
                counter <= 7;
                data_in <= m_data_i;
                m_busy_o <= 1'b1;
                state <= S5;
            end
            end
            S11: begin // master stop
                    if (neg_clk) begin
                        if (s_stop == 1'b0) begin
                            sda_out <= 1'b0; 
                        end
                     end else if (pos_clk) begin
                        if (s_stop == 1'b0) begin
                            sda_out <= 1'b1;
                            s_stop  <= 1'b1;
                        end else begin
                            m_busy_o <= 1'b0;
                            state<= S0;
                        end
                    end
            end

        endcase

    end

end

endmodule

module clk_DIVIDER(
input clk,
input rst,
output reg pos_clk,
output reg neg_clk,
output reg SCL
);

parameter DIVIDER  = 10;
reg [9:0] counter = 0;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 10'b0;
        SCL <= 1'b1;
        pos_clk <= 1'b0;
        neg_clk <= 1'b0;
    end else begin
        pos_clk <= 1'b0;
        neg_clk <= 1'b0;
     if (counter == DIVIDER - 1) begin
        counter <= 0;
        if (!SCL) begin
        SCL <= 1'b1;
        pos_clk <= 1'b1;
        end else begin
        SCL <= 1'b0;
        neg_clk <= 1'b1;
        end
    end else begin
        counter <= counter + 1'b1;
    end
end
end
endmodule

