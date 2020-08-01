module rd_wr_manager (
    input                 sys_clk           ,   //系统时钟
    input                 sys_rst_n         ,   //系统复位，低电平有效
    
//需管理的信号
    input                 lcd_rd_en         ,   //lcd读请求
    input                 rgb2gray_wr_en    ,   //rgb2gray模块写请求
    input                 morph_wr_en    ,   //morph_1D_wr_en模块写请求
    input                 shot_done         ,   //摄像头拍摄完成
    
//输出读/写使能信号
    output reg            rd_en             ,   //读使能
    output reg            wr_en             ,   //写使能
    
//输出读、写起始地址
    output reg [23:0]     rd_min_addr       ,   //读地址
    output reg [23:0]     wr_min_addr       ,   //读地址
   
    output reg            lcd_rst_n             //lcd复位信号,需要时赋值为1即可调用lcd
);

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        rd_en <= 1'b0;
        wr_en <= 1'b0;
        lcd_rst_n <= 1'b0;
        rd_min_addr <= 24'b0;
        wr_min_addr <= 24'b0;
    end
    
    else if(rgb2gray_wr_en == 1) begin
        //wr_min_addr = 24'd10000;
        //rd_min_addr = 24'd10000;
        wr_en <= 1'b1;
        lcd_rst_n <= 1'b1;
        end
    else if(morph_wr_en == 1) begin
        wr_en = 1'b1;
        lcd_rst_n = 1'b1;
        end
    else begin
        rd_en = 1'b0;
        wr_en = 1'b0;
    end
end

endmodule