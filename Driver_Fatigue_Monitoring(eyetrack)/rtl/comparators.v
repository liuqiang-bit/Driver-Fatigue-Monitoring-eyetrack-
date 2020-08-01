module comparators (

    input   module_clk              ,           //系统时钟
    input   module_rst_n            ,           //系统服务信号
    
    input   din_val                 ,           //输入数据有效标志
    input   din_a                   ,           //输入的数据a    
    input   din_b                   ,           //输入的数据b
    
    output  reg[7:0]    dout_min    ,           //输出最小值
    output  reg[7:0]    dout_max                //输出最大值
    );
    

//有效数据滞后于请求信号一个时钟周期,所以数据有效信号在此延时一拍
always @(posedge module_clk or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        dout_min <= 1'b0    ;
        dout_max <= 1'b0    ;
    end
    
    else if( din_val == 1 ) begin
        dout_min <= ( din_a < din_b ) ? din_a : din_b     ;   
        dout_max <= ( din_a >= din_b ) ? din_a : din_b    ;          
    end 
    
    else    ;
end    
    
endmodule