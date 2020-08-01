module morph_row (

    input   module_clk                  ,           //数据入栈时钟
    input   module_clk2                 ,           //打拍时钟
    input   cam_href                    ,           //行同步信号，用于复位计数器
    input   cam_vsync                   ,           //场同步信号
    input   module_rst_n                ,           //系统服务信号
    
    input   EPS_CRS                     ,           //膨胀或腐蚀选择，1 膨胀，0 腐蚀
    input   din_val                     ,           //输入数据有效标志
    input   din                         ,           //输入的数据a    

    output  reg        morph_row_wr_en    ,         //SDRAM写请求信号
    output  reg             cam_href_r    ,         //SDRAM写请求信号
    output  reg             cam_vsync_r   ,         //SDRAM写请求信号
    output  reg [7:0]       dout_EPS8b    ,         //8位膨胀数据
    output  reg [7:0]       dout_CRS8b    ,         //8位膨胀数据
    
    output  reg             dout_EPS1b    ,         //1位膨胀数据
    output  reg             dout_CRS1b              //1位膨胀数据
 
    );

wire          cnt_rst               ;        //cnt复位
    
reg  [11:0]   cnt                   ;        //流入计数   
reg  [2:0]    data_3                ;        //容量为3的数据栈

//************数据有效信号打拍***********//

reg           morph_row_wr_en0       ;
reg           morph_row_wr_en1       ;
reg           morph_row_wr_en2       ;
reg           morph_row_wr_en3       ;
reg           morph_row_wr_en4       ;

//************数据有效信号打拍***********//

//*************行同步信号打拍************//

reg           cam_href_r0         ;
reg           cam_href_r1         ;
reg           cam_href_r2         ;
reg           cam_href_r3         ;

//************数据有效信号打拍***********//

//*************场同步信号打拍************//

reg           cam_vsync_r0         ;
reg           cam_vsync_r1         ;
reg           cam_vsync_r2         ;
reg           cam_vsync_r3         ;

//************数据有效信号打拍***********//

//检测cam_href上升沿，检测到上升沿，cnt置零
assign cnt_rst = (~cam_href_r1) & (cam_href_r0)    ;

//行同步信号打一拍
always @(posedge module_clk or negedge module_rst_n) begin
    if(!module_rst_n) begin
        cam_href_r0 <= 1'b0    ;
        cam_href_r1 <= 1'b0    ;
        cam_href_r  <= 1'b0    ;
    end
    
    else begin
        cam_href_r0 <= cam_href     ;
        cam_href_r1 <= cam_href_r0  ; 
        cam_href_r  <= cam_href_r1  ; 
        
    end
end

//场同步信号打一拍
always @(posedge module_clk or negedge module_rst_n) begin
    if(!module_rst_n) begin
        cam_vsync_r0 <= 1'b0    ;
        cam_vsync_r1 <= 1'b0    ;
        cam_vsync_r  <= 1'b0    ;
    end
    
    else begin
        cam_vsync_r0 <= cam_vsync     ;
        cam_vsync_r1 <= cam_vsync_r0  ; 
        cam_vsync_r  <= cam_vsync_r1  ; 
        
    end
end
//计数模块
always @(posedge module_clk or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        cnt <= 12'd0    ;
    end      
    else if( cnt_rst == 1 )
        cnt <= 0    ;       
    else 
        cnt <= cnt + 12'd1   ;  
end 

//数据入栈
always @(posedge din_val or negedge module_rst_n) begin
    if( !module_rst_n ) 
        data_3 <= 3'b0    ;
        
    else
        data_3 <= { data_3[1:0] , din }    ;                  
end    

//膨胀或腐蚀
always @(posedge module_clk2 or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        dout_EPS8b <= 8'd0    ;
        dout_CRS8b <= 8'd0    ;
        dout_EPS1b <= 1'd0    ;
        dout_CRS1b <= 1'd0    ;
    end
    
    else if( EPS_CRS == 1) begin            //腐蚀
        if((cnt == 5 || cnt == 644)) begin
            dout_CRS8b <= 8'd0     ;
            dout_CRS1b <= 1'd0     ;           
        end   
        else if(cnt >5 && cnt < 644) begin
            dout_CRS8b <= (( data_3[2] & 1'b1 ) | ( data_3[0] & 1'b1 ) ) ? 8'd255 : 8'd0    ;   
            dout_CRS1b <= (( data_3[2] & 1'b1 ) | ( data_3[0] & 1'b1 ) ) ? 1'd1   : 1'd0    ;    
        end 
    end
    else if( EPS_CRS == 0 ) begin           //膨胀
        if((cnt == 5 || cnt == 644)) begin
            dout_EPS8b <= 8'd0   ;
            dout_EPS1b <= 1'd0   ;
        end    
        else if(cnt >5 && cnt < 644) begin
            dout_EPS8b <= (( data_3[2] & 1'b1 ) & ( data_3[0] & 1'b1 ) ) ? 8'd255 : 8'd0    ;    
            dout_EPS1b <= (( data_3[2] & 1'b1 ) & ( data_3[0] & 1'b1 ) ) ? 1'd1   : 1'd0    ;    
        end
    end 
end
//数据有效信号对齐输出数据
always @(posedge module_clk2 or negedge module_rst_n) begin
    if(!module_rst_n) begin
        morph_row_wr_en  <= 1'b0    ;
        morph_row_wr_en0 <= 1'b0    ;
        morph_row_wr_en1 <= 1'b0    ;
        morph_row_wr_en2 <= 1'b0    ;
        morph_row_wr_en3 <= 1'b0    ;
        morph_row_wr_en4 <= 1'b0    ;
    end
    
    else begin
        morph_row_wr_en0 <= din_val             ;  
        morph_row_wr_en1 <= morph_row_wr_en0    ;
        morph_row_wr_en2 <= morph_row_wr_en1    ;
        morph_row_wr_en3 <= morph_row_wr_en2    ;
        morph_row_wr_en4 <= morph_row_wr_en3    ;
        morph_row_wr_en  <= morph_row_wr_en4    ;
    end
end


endmodule