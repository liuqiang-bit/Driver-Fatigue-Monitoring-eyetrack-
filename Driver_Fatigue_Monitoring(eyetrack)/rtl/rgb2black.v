
/********************************************RGB转灰度公式************************************************************************************************
    
    获取高字节的5个bit
    R = color & 0xF800;
    获取中间6个bit
    G = color & 0x07E0;
    获取低字节5个bit
    B = color & 0x001F;
    Gray = (R*19595 + G*38469 + B*7472) >> 16
    data_from_sdram_temp[rd_cnt] <= ((data_from_sdram & 0xF800) * 38 + (data_from_sdram & 0x07E0) * 75 + (data_from_sdram & 0x001F) * 15) >> 7;
　　2至20位精度的系数：
                          Gray = (R*1 + G*2 + B*1) >> 2
                          Gray = (R*2 + G*5 + B*1) >> 3
                          Gray = (R*4 + G*10 + B*2) >> 4
                          Gray = (R*9 + G*19 + B*4) >> 5
                          Gray = (R*19 + G*37 + B*8) >> 6
                          Gray = (R*38 + G*75 + B*15) >> 7
                          Gray = (R*76 + G*150 + B*30) >> 8
                          Gray = (R*153 + G*300 + B*59) >> 9
                          Gray = (R*306 + G*601 + B*117) >> 10
                          Gray = (R*612 + G*1202 + B*234) >> 11
                          Gray = (R*1224 + G*2405 + B*467) >> 12
                          Gray = (R*2449 + G*4809 + B*934) >> 13
                          Gray = (R*4898 + G*9618 + B*1868) >> 14
                          Gray = (R*9797 + G*19235 + B*3736) >> 15
                          Gray = (R*19595 + G*38469 + B*7472) >> 16
                          Gray = (R*39190 + G*76939 + B*14943) >> 17
                          Gray = (R*78381 + G*153878 + B*29885) >> 18
                          Gray = (R*156762 + G*307757 + B*59769) >> 19
                          Gray = (R*313524 + G*615514 + B*119538) >> 20
                          
*********************************************************************************************************************************************************/
                          
module rgb2black(
    input             module_clk          ,           //读数据时钟
    input             module_rst_n        ,           //低电平复位信号
    
    //摄像头信号
    input             data_val            ,           //摄像头数据有效信号
    input   [15:0]    din                 ,           //摄像头输出数据
    
    //模块输出
    output  reg       rgb2black_wr_en     ,           //SDRAM写请求信号
    output  reg[7:0]  dout_gray           ,           //灰度数据
    
    //保留眼部细节
    output  reg[7:0]  dout_binary8b       ,            //8位二值数据
    output  reg       dout_binary1b       ,            //1位二值数据

    //不保留细节，用于定位人脸
    output  reg[7:0]  dout_binary8b_face  ,            //8位二值数据
    output  reg       dout_binary1b_face               //1位二值数据
    );

//**************三原色分量******************//

reg    [7:0]    R                   ;
reg    [7:0]    G                   ;
reg    [7:0]    B                   ;

//*****************************************//

//************三原色分量乘法结果*************//

reg    [15:0]   Rx                  ;
reg    [15:0]   Gx                  ;
reg    [15:0]   Bx                  ;

//*****************************************//

//***********二值化************************//

reg    [7:0]     binary_threshold1    ;           //二值化阈值
reg    [7:0]     binary_threshold2    ;           //二值化阈值

//*****************************************//

reg       rgb2black_wr_en0     ;           //SDRAM写请求信号
reg       rgb2black_wr_en1     ;           //SDRAM写请求信号
reg       rgb2black_wr_en2     ;           //SDRAM写请求信号
reg       rgb2black_wr_en3     ;           //SDRAM写请求信号
reg       rgb2black_wr_en4     ;           //SDRAM写请求信号
reg       rgb2black_wr_en5     ;           //SDRAM写请求信号


//提取RGB分量，并扩展为RGB888
always @(posedge module_clk) begin
    if(!module_rst_n) begin
        R <= 8'd0   ;
        G <= 8'd0   ;
        B <= 8'd0   ;
    end
    
    else if(data_val) begin
        R <= { din[15:11] , din[13:11] }    ;
        G <= { din[10:5] , din[6:5] }       ;
        B <= { din[4:0] , din[2:0] }        ;
    end
end

//计算乘法
always @(posedge module_clk) begin
    if(!module_rst_n) begin
        Rx <= 16'd0;
        Gx <= 16'd0;
        Bx <= 16'd0;
    end
    
    else if(data_val) begin
        Rx <= ( R << 6 ) + ( R << 3 ) + ( R << 1 ) + R              ;       //R*75
        Gx <= ( G << 7 ) + ( G << 4 ) + ( G << 2 ) + ( G << 1 )     ;		//G*150
        Bx <= ( B << 4 ) + ( B << 3 ) + ( B << 2 ) + ( B << 1 )     ;		//B*30
    end
end

//计算灰度值
always @(posedge module_clk) begin
    if(!module_rst_n) begin
        dout_gray <= 8'd0    ;

    end
    else if(data_val) begin
        dout_gray <= (Rx + Gx + Bx) >> 8    ;
    end   
    
end

//保留眼部细节二值化
always @(posedge module_clk) begin
    if(!module_rst_n) begin
        dout_binary8b <= 8'd0         ;       
        dout_binary1b <= 1'd0         ;              
        binary_threshold1 <= 8'd130    ;            //设定阈值
    end
    
    else if(data_val) begin
        if (dout_gray <= binary_threshold1) begin
            dout_binary8b <= 8'd0      ;
            dout_binary1b <= 1'd0      ;
        end
        
        else begin
            dout_binary8b <= 8'd255    ;
            dout_binary1b <= 1'd1      ;
        end
    end
end

//不保留细节二值化
always @(posedge module_clk) begin
    if(!module_rst_n) begin
        dout_binary8b_face <= 8'd0         ;       
        dout_binary1b_face <= 1'd0         ;              
        binary_threshold2 <= 8'd110    ;            //设定阈值
    end
    
    else if(data_val) begin
        if (dout_gray <= binary_threshold2) begin
            dout_binary8b_face <= 8'd0      ;
            dout_binary1b_face <= 1'd0      ;
        end
        
        else begin
            dout_binary8b_face <= 8'd255    ;
            dout_binary1b_face <= 1'd1      ;
        end
    end
end
//数据有效信号对齐输出数据，lcd显示结果
always @(posedge module_clk) begin
    if(!module_rst_n) begin
        rgb2black_wr_en0 <= 1'b0     ;
        rgb2black_wr_en1 <= 1'b0     ;
        rgb2black_wr_en2 <= 1'b0     ;
        rgb2black_wr_en3 <= 1'b0     ;
        rgb2black_wr_en4 <= 1'b0     ;
        rgb2black_wr_en5 <= 1'b0     ;
        rgb2black_wr_en <= 1'b0      ;
    end
    
    else begin
        rgb2black_wr_en0 <= data_val    ;  
        rgb2black_wr_en1 <= rgb2black_wr_en0    ;
        rgb2black_wr_en2 <= rgb2black_wr_en1    ;
        rgb2black_wr_en3 <= rgb2black_wr_en2    ;
        rgb2black_wr_en4 <= rgb2black_wr_en3    ;
        rgb2black_wr_en5 <= rgb2black_wr_en4    ;
        rgb2black_wr_en <= rgb2black_wr_en5     ;
       end
end


endmodule