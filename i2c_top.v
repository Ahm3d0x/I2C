module i2c_top (
    input clk, //1
    input rst, //2

    // master side
    input        m_start_i, //3
    input        m_stop_i,  //4
    input [6:0]  m_slv_add_i,//5
    input        m_w_r_i,   //6
    input [7:0]  m_data_i,  //7
    input        m_ack_i,   //8
    output [7:0] m_data_o,  //9
    output       m_busy_o,  //10  
    output       m_data_ready_o, //11    
    output       m_error_o, //12



    // slave side
    output [7:0] s_data_o, //13
    input  [7:0] s_data_i,  //14
    output       s_we_i //  //15
);



    // internal i2c bus lines
    //////////////////////////////////////////////
    //////////////////////////////////////////////
    //////////////////////////////////////////////
    //////////////////////////////////////////////
    wire SDA;   //16
    wire SCL;   //17
    //////////////////////////////////////////////
    //////////////////////////////////////////////
    //////////////////////////////////////////////
    //////////////////////////////////////////////


    // master instantiation
    master master_inst (
        .clk(clk), //1
        .rst(rst), //2
        .m_start_i(m_start_i), //3 
        .m_stop_i(m_stop_i), //4
        .m_slv_add_i(m_slv_add_i),//5
        .m_w_r_i(m_w_r_i), //6
        .m_data_i(m_data_i), //7
        .m_ack_i(m_ack_i), //8
        .m_data_o(m_data_o), //9
        .m_busy_o(m_busy_o), //10
        .m_data_ready_o(m_data_ready_o), //11
        .m_error_o(m_error_o),  //12
        .SDA(SDA),  //16
        .SCL(SCL)   //17
    );

    // slave instantiation
    slave slave_inst (
        .clk(clk), //1
        .rst(rst), //2
        .SDA(SDA), //16
        .SCL(SCL), //17 
        .data_o(s_data_o), //13
        .data_i(s_data_i), //14
        .we_i(s_we_i) //15
    );

endmodule