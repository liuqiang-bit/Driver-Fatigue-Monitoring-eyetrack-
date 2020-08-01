module eye_pst (
    input module_clk                            ,          //模块工作时钟
    input module_rst_n                          ,          //模块复位时钟
        
    input din_val                               ,          //数据有效信号
    input din                                   ,          //输入数据
    input [10:0] lcd_pixel_xpos                 ,          //像素点在lcd屏幕上的横坐标
    input [10:0] lcd_pixel_ypos                 ,          //像素点在lcd屏幕上的纵坐标 
    
    input [11:0] face_left                      ,          //脸左边界
    input [11:0] face_right                     ,          //脸左边界
    input [11:0] face_up                        ,          //脸上边界
    input [11:0] face_down                      ,          //脸下边界
    input [11:0] face_widest_r                  ,          //脸最宽的行    
 

    output  reg[10:0] eye1_up                   ,          //眼睛上边界
    output  reg[10:0] eye1_down                 ,          //眼睛下边界 
    output  reg[10:0] eye1_left                 ,          //眼睛左边界
    output  reg[10:0] eye1_right                ,          //眼睛左边界

    output  reg[10:0] eye2_up                   ,          //眼睛上边界
    output  reg[10:0] eye2_down                 ,          //眼睛下边界    
    output  reg[10:0] eye2_left                 ,          //眼睛左边界
    output  reg[10:0] eye2_right                           //眼睛左边界
//
//    output  reg[10:0] eye1_high                 ,
//    output  reg[10:0] eye2_high                 ,  
//    output  reg[10:0] eye1_wide                 ,
//    output  reg[10:0] eye2_wide                 
);


wire [10:0]      px_x    ;          //像素在显示区域的横坐标
wire [10:0]      px_y    ;           //像素在显示区域的纵坐标
wire [11:0]      face_left2    ;           //像素在显示区域的横坐标
wire [11:0]      face_right2   ;           //像素在显示区域的纵坐标
wire [10:0]      center      ;
reg  [10:0]      rsta_tmp1       ;      //行方向黑色像素统计值
reg  [1:0]            rsta1  ;
reg  [10:0]      rsta_tmp2       ;      //行方向黑色像素统计值
reg  [1:0]            rsta2   ;

reg            eye1_up_get   ;
reg            eye2_up_get   ;

reg            eyebrows1_up_get      ;
reg            eyebrows1_down_get      ;
reg            eyebrows2_up_get      ;
reg            eyebrows2_down_get      ;

reg  [10:0]      eye1_up_tmp      ;
reg  [10:0]      eye1_down_tmp      ;
reg  [10:0]      eye1_left_tmp      ;
reg  [10:0]      eye1_right_tmp      ;

reg  [10:0]      eye2_up_tmp      ;
reg  [10:0]      eye2_down_tmp      ;
reg  [10:0]      eye2_left_tmp      ;
reg  [10:0]      eye2_right_tmp      ;


reg  [2:0]      state1           ;
reg  [2:0]      state2           ;

assign face_left2  = face_left + ((face_right - face_left) >> 3 );
assign face_right2 = face_right - ((face_right - face_left) >> 3 );

assign center = (face_right + face_left) >> 1  ;

assign  px_x = lcd_pixel_xpos - 79  ;
assign  px_y = lcd_pixel_ypos       ;


//行统计
always @(posedge module_clk  or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        rsta_tmp1 <= 11'd0   ;
    end      
    else if( px_x >= face_left2 && px_x <= center &&  px_y >= face_up && px_y <= face_widest_r) begin
        if(din == 0) begin
            rsta_tmp1 <= rsta_tmp1 + 1  ;   
        end
    end  
    else if( px_x == 640) begin
            rsta_tmp1 <= 11'd0   ;
    end  
     
end 

//行统计
always @(posedge module_clk  or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        rsta1 <= 2'd0   ;
    end      
    else if(px_x == (center-2) && px_y >= face_up && px_y <= face_widest_r) begin          
        rsta1 <= ( rsta_tmp1 > 0 ) ? 1 : 0 ;       
    end  
    else if(px_y < face_up || px_y > face_widest_r)
        rsta1 <= 2   ;
end 

//行统计
always @(posedge module_clk  or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        rsta_tmp2 <= 11'd0   ;
    end      
    else if( px_x > center && px_x <= face_right2 &&  px_y >= face_up && px_y <= face_widest_r) begin
        if(din == 0) begin
            rsta_tmp2 <= rsta_tmp2 + 1  ;   
        end
    end  
    else if( px_x == 640) begin
        rsta_tmp2 <= 11'd0   ;
    end  
     
end 

//行统计
always @(posedge module_clk  or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        rsta2 <= 2'd0   ;
    end      
    else if(px_x == (face_right2 - 2) && px_y >= face_up && px_y <= face_widest_r) begin          
        rsta2 <= ( rsta_tmp2 > 0 ) ? 1 : 0 ;       
    end  
    else if(px_y < face_up || px_y > face_widest_r)
        rsta2 <= 2   ;
end 

//眼睛上下边界
always @(posedge module_clk or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        state1     <= 3'd0     ;
        state2     <= 3'd0     ;
        
        eye1_up    <= 11'd0    ;
        eye1_down  <= 11'd0    ;
//        eye1_high  <= 11'd0    ;
        
        eye2_up    <= 11'd0    ;
        eye2_down  <= 11'd0    ;
//        eye2_high  <= 11'd0    ;
        
        eyebrows1_up_get   <= 1'd0     ; 
        eyebrows1_down_get <= 1'd0     ;  
        eyebrows2_up_get   <= 1'd0     ; 
        eyebrows2_down_get <= 1'd0     ; 
        
        
        eye1_up_tmp    <= 11'd0     ;
        eye1_down_tmp  <= 11'd0     ;
        
        eye2_up_tmp    <= 11'd0     ;
        eye2_down_tmp  <= 11'd0     ;

    end   
    
    //屏幕上的左眼，实际的右眼
    else if( px_x >= face_left2 && px_x <= center &&  px_y >= face_up && px_y <= face_widest_r) begin 
        //到达眉眼区域第一个像素，状态机转到状态1
        if( px_y == face_up ) begin
            state1 <= 1  ;
        end
        
        //开始寻找眉毛上边界
        else if (state1 == 1) begin
            if(rsta1 == 0) begin
                eyebrows1_up_get <= 1'd1    ;
            end
            else if(rsta1 == 1 && eyebrows1_up_get == 1 && px_x == center) begin
                state1 <= 2      ;
            end
        end
        
        //寻找眉毛下边界
        else if (state1 == 2) begin
            if(rsta1 == 1) begin
                eyebrows1_down_get <= 1'd1    ;
            end
            else if(rsta1 == 0 && eyebrows1_down_get == 1 && px_x == center) begin
                state1 <= 3      ;
            end
        end
        
        //寻找眼睛1上边界
        else if (state1 == 3) begin
        if(rsta1 == 0) begin
                eye1_up_tmp <= px_y     ;
                eye1_up_get <= 1'd1    ;
            end
            else if(rsta1 == 1 && eye1_up_get == 1 && px_x == center) begin
                state1 <= 4      ;
            end
        end
        
        //寻找眼睛1下边界
        else if (state1 == 4) begin
        if(rsta1 == 1 ) begin
                eye1_down_tmp <= px_y     ;
            end
        end
    end 
    
    //屏幕上的右眼，实际的左眼
    else if( px_x > center && px_x <= face_right2 &&  px_y >= face_up && px_y <= face_widest_r) begin 
        //到达眉眼区域第一个像素，状态机转到状态1
        if( px_y == face_up ) begin
            state2 <= 1  ;
        end
        
        //开始寻找眉毛上边界
        else if (state2 == 1) begin
            if(rsta2 == 0) begin
                eyebrows2_up_get <= 1'd1    ;
            end
            else if(rsta2 == 1 && eyebrows2_up_get == 1 && px_x == face_right2) begin
                state2 <= 2      ;
            end
        end
        
        //寻找眉毛下边界
        else if (state2 == 2) begin
            if(rsta2 == 1) begin
                eyebrows2_down_get <= 1'd1    ;
            end
            else if(rsta2 == 0 && eyebrows2_down_get == 1 && px_x == face_right2) begin
                state2 <= 3      ;
            end
        end
        
        //寻找眼睛1上边界
        else if (state2 == 3) begin
        if(rsta2 == 0) begin
                eye2_up_tmp <= px_y     ;
                eye2_up_get <= 1'd1    ;
            end
            else if(rsta2 == 1 && eye2_up_get == 1 && px_x == face_right2) begin
                state2 <= 4      ;
            end
        end
        
        //寻找眼睛1下边界
        else if (state2 == 4) begin
        if(rsta2 == 1 ) begin
                eye2_down_tmp <= px_y     ;
            end
        end
    end 
    else if( px_y == 480  && px_x == 640) begin
        state1 <= 1      ;
        state2 <= 1      ;
        
        eye1_up_get <= 1'd0    ;   
        eyebrows1_up_get <= 1'd0    ; 
        eyebrows1_down_get <= 1'd0    ;
        eye1_up <= eye1_up_tmp          ;
        eye1_down <= eye1_down_tmp    ;
//        eye1_high  <= eye1_down_tmp - eye1_up_tmp   ;
        
        eye2_up_get <= 1'd0    ;   
        eyebrows2_up_get <= 1'd0    ; 
        eyebrows2_down_get <= 1'd0    ;
        eye2_up <= eye2_up_tmp    ;
        eye2_down <= eye2_down_tmp    ;
//        eye2_high  <= eye2_down_tmp - eye2_up_tmp   ;
    end
    
end 

//确定眼睛左右边界
always @(posedge module_clk  or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        eye1_left  <= 11'd640    ;
        eye1_right <= 11'd0    ;
        
        eye2_left  <= 11'd640    ;
        eye2_right <= 11'd0    ;
        
        eye1_left_tmp  <= 11'd640     ;
        eye1_right_tmp <= 11'd0     ;
        
        eye2_left_tmp  <= 11'd640     ;
        eye2_right_tmp <= 11'd0     ;
        
//        eye1_wide <= 11'd0  ;
//        eye2_wide <= 11'd0  ;
    end      
    else if( px_x >= face_left2 && px_x <= center &&  px_y >= face_up && px_y <= face_widest_r) begin 
        if(state1 == 4) begin
            if(din == 0) begin
                if(px_x < eye1_left_tmp) begin
                    eye1_left_tmp <= px_x   ;
                end
                else if(px_x > eye1_right_tmp) begin
                    eye1_right_tmp <= px_x   ;
                end
            end
        end
    end      
    else if( px_x > center && px_x <= face_right2 &&  px_y >= face_up && px_y <= face_widest_r) begin 
        if(state2 == 4) begin
            if(din == 0) begin
                if(px_x < eye2_left_tmp) begin
                    eye2_left_tmp <= px_x   ;
                end
                else if(px_x > eye2_right_tmp) begin
                    eye2_right_tmp <= px_x   ;
                end
            end
        end
    end  
    else if( px_y == 480 && px_x == 640 ) begin
        eye1_left <= eye1_left_tmp  ;
        eye1_right <= eye1_right_tmp    ;
        eye2_left <= eye2_left_tmp  ;
        eye2_right <= eye2_right_tmp    ;
//        eye1_wide <= eye1_right_tmp - eye1_left_tmp ;
//        eye2_wide <= eye2_right_tmp - eye2_left_tmp ;
        
        eye1_left_tmp  <= 11'd640     ;
        eye1_right_tmp <= 11'd0     ;
        
        eye2_left_tmp  <= 11'd640     ;
        eye2_right_tmp <= 11'd0     ;
    end
end 
endmodule