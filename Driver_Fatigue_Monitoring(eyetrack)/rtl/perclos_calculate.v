module perclos_calculate (
    input   module_clk,
    input   module_rst_n,
    input  [10:0]lcd_pixel_xpos,          
    input  [10:0]lcd_pixel_ypos,          
    
    input  [10:0] eye_high,
    input  [10:0] eye_wide , 
    
    output           beep
    );
    
reg  [12:0]   eye_close_cnt       ;          //闭眼帧数记录
reg  [12:0]   eye_open_cnt        ;          //睁眼帧数记录    
reg  [12:0]   eye_close_cnt_tmp   ;          //闭眼帧数记录
reg  [12:0]   eye_open_cnt_tmp    ;          //睁眼帧数记录
reg  [12:0]   all_cnt             ;          //计数总帧率
reg  [12:0]   eye_close_lx        ;
wire [4:0]    aspectratio         ;          //长宽比

wire new_image  ;           //新帧标志
wire image_end  ;           //一帧结束标志

assign new_image = ( lcd_pixel_xpos == 1 && lcd_pixel_ypos == 1 ) ? 1'd1 : 1'd0     ;           //每帧第1个像素表示新帧开始
assign image_end = ( lcd_pixel_xpos == 1 && lcd_pixel_ypos == 480 ) ? 1'd1 : 1'd0     ;         

assign aspectratio = eye_wide / eye_high    ;

//总帧数计数器
always @( posedge module_clk  or negedge module_rst_n ) begin
    if( !module_rst_n ) begin
        all_cnt <= 13'd0   ;
    end
    
    else if( new_image )begin
        if(all_cnt < 5400 ) begin
            all_cnt <= all_cnt + 1  ;
        end
        else if( all_cnt == 5400 )begin
            all_cnt <= 13'd0  ;
        end
    end
end 

always @( posedge module_clk  or negedge module_rst_n ) begin
    if( !module_rst_n ) begin
        eye_close_cnt <= 13'd0   ;
        eye_open_cnt  <= 13'd0   ;
        eye_close_cnt_tmp <= 13'd0   ;
        eye_open_cnt_tmp  <= 13'd0   ;
        eye_close_lx <= 13'd0   ;
    end
    
    else if( new_image == 1 && all_cnt < 5400)begin
        if( aspectratio > 3 ) begin             //横纵比> 3 就认为闭眼了
            eye_close_cnt_tmp <= eye_close_cnt_tmp + 1    ;
            eye_close_lx <= eye_close_lx + 1    ;
        end
        else begin
            eye_open_cnt_tmp <= eye_open_cnt_tmp + 1    ;
            eye_close_lx <= 13'd0   ;
        end
    end
    
    else if( image_end == 1 && all_cnt == 5400 )begin
        eye_close_cnt <= eye_close_cnt_tmp  ;
        eye_open_cnt <= eye_open_cnt_tmp    ;
        
        eye_close_cnt_tmp <= 13'd0   ;
        eye_open_cnt_tmp  <= 13'd0   ;
    end    
    
end 


assign beep = (eye_close_lx > 13'd120) ? 0 : 1 ;


endmodule