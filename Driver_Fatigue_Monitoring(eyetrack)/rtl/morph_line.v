module morph_line (
    input module_clk                      ,          //模块工作时钟
    input module_clk2                     ,          //模块打拍时钟

    input module_rst_n                    ,          //模块复位时钟
    input cam_href                        ,          //行同步信号，用于复位计数器
    input cam_vsync                       ,          //场同步信号

    input din_val                         ,          //数据有效信号
    input din                             ,          //输入数据
    input EPS_CRS                         ,          //膨胀或腐蚀，1 腐蚀，0 膨胀
    
    output  reg          morph_line_wr_en ,          //SDRAM写请求信号、数据有效信号
    
    output                  cam_href_r    ,           //行同步信号
    output                  cam_vsync_r   ,           //场同步信号
    //8位输出用于LCD显示
    output  reg [7:0]       dout_EPS8b    ,          //8位膨胀数据
    output  reg [7:0]       dout_CRS8b    ,          //8位膨胀数据
    
    //1位输出用于后续模块处理
    output  reg             dout_EPS1b    ,          //1位膨胀数据
    output  reg             dout_CRS1b               //1位膨胀数据
);

reg [1280:0]  data_1281     ;       

//**************计数器及复位*************//

reg [11:0]    cnt_r         ;           //行计数
wire          cnt_rrst      ;           //行计数器复位
wire          cnt_lrst      ;           //列计数器复位

//**************************************//

//*************行同步信号打拍************//

reg           cam_href_r0         ;
reg           cam_href_r1         ;

//*************************************//

//*************场同步信号打拍************//

reg           cam_vsync_r0         ;
reg           cam_vsync_r1         ;

//*************************************//


//检测cam_href上升沿，检测到上升沿
assign cnt_lrst = (~cam_href_r1) & (cam_href_r0)   ;

//检测cam_vsync上升沿，检测到上升沿
assign cnt_rrst = (~cam_vsync_r1) & (cam_vsync_r0) ;

//同步信号不打拍直接输出
assign cam_href_r = cam_href   ;
assign cam_vsync_r = cam_vsync ;


//************************信号打拍*************************//

//行同步信号打一拍
always @(posedge module_clk or negedge module_rst_n) begin
    if(!module_rst_n) begin
        cam_href_r0 <= 1'b0    ;
        cam_href_r1 <= 1'b0    ;
    end
    
    else begin
        cam_href_r0 <= cam_href     ;
        cam_href_r1 <= cam_href_r0  ;
    end
end

//场同步信号打一拍
always @(posedge module_clk or negedge module_rst_n) begin
    if(!module_rst_n) begin
        cam_vsync_r0 <= 1'b0    ;
        cam_vsync_r1 <= 1'b0    ;
    end
    
    else begin
        cam_vsync_r0 <= cam_vsync     ;
        cam_vsync_r1 <= cam_vsync_r0  ;
    end
end

//数据有效信号打拍
always @(posedge module_clk2 or negedge module_rst_n) begin
    if(!module_rst_n) begin
        morph_line_wr_en <= 1'b0    ;
    end
    
    else begin
        morph_line_wr_en <= din_val     ;
        
    end
end
//********************************************************//

//行计数模块
always @(posedge module_clk or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        cnt_r <= 12'd0    ;
    end   
    else if(cnt_rrst )             //检测到场同步信号上升沿，计数器置零
        cnt_r <= 12'd0    ;   
    else if(cnt_lrst)              //检测等到行同步信号上升沿，计数器加1
        cnt_r <= cnt_r + 12'd1   ;  
       
end 

//数据入栈
always @(posedge din_val or negedge module_rst_n) begin
    if( !module_rst_n ) 
        data_1281 <= 1280'b0    ;
        
    else
        data_1281 <= { data_1281[1279:0] , din }    ;                  
end 
   
//形态学处理
always @(posedge module_clk2 or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        dout_EPS8b <= 8'd0    ;
        dout_CRS8b <= 8'd0    ;
        dout_EPS1b <= 1'd0    ;
        dout_CRS1b <= 1'd0    ;
    end
    
    else if( EPS_CRS == 1) begin            //腐蚀
        if(cnt_r <= 2 ) begin
            dout_CRS8b <= 8'd0     ;
            dout_CRS1b <= 1'd0     ;           
        end   
        else if(cnt_r != 2) begin
            dout_CRS8b <= (( data_1281[1280] & 1'b1 ) | ( data_1281[0] & 1'b1 ) ) ? 8'd255 : 8'd0    ;   
            dout_CRS1b <= (( data_1281[1280] & 1'b1 ) | ( data_1281[0] & 1'b1 ) ) ? 1'd1   : 1'd0    ;       
        end       
    end
    
    else if( EPS_CRS == 0 ) begin           //膨胀
        if(cnt_r <= 2 ) begin
            dout_CRS8b <= 8'd0     ;
            dout_CRS1b <= 1'd0     ;           
        end   
        else if(cnt_r != 2) begin
            dout_EPS8b <= (( data_1281[1280] & 1'b1 ) & ( data_1281[0] & 1'b1 ) ) ? 8'd255 : 8'd0    ;    
            dout_EPS1b <= (( data_1281[1280] & 1'b1 ) & ( data_1281[0] & 1'b1 ) ) ? 1'd1   : 1'd0    ;    
        end
    end 
end
   endmodule