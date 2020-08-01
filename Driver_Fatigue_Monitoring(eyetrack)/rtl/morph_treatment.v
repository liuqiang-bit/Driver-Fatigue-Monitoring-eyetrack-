module morph_treatment (

    input   module_clk,             //系统时钟
    input   module_rst_n,           //系统服务信号
    
    input   data_val,               //数据有效信号    
    input   row_data,               //输入的数据
    
    output  morth_wr_en,            //模块写SDRAM请求
    output  dld_data                //处理完的数据
    );
    

////有效数据滞后于请求信号一个时钟周期,所以数据有效信号在此延时一拍
//always @(posedge module_clk or negedge module_rst_n) begin
//    if(!sys_rst_n)
//        data_val <= 1'b0;
//    else
//        data_val <= data_req;    
//end    
//    
//    
    endmodule