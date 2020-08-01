module eye_track(
    input module_clk                ,          //模块工作时钟
    input module_rst_n              ,          //模块复位时钟
    
    input touch_key                 ,          //触摸按键     
    input din_val                   ,          //数据有效信号
    input din                       ,          //输入数据
    
    input [10:0] lcd_pixel_xpos     ,          //像素点在lcd屏幕上的横坐标
    input [10:0] lcd_pixel_ypos     ,          //像素点在lcd屏幕上的纵坐标  

    input  [10:0] eye1_up           ,          //眼睛上边界
    input  [10:0] eye1_down         ,          //眼睛下边界 
    input  [10:0] eye1_left         ,          //眼睛左边界
    input  [10:0] eye1_right        ,          //眼睛左边界

    input  [10:0] eye2_up           ,          //眼睛上边界
    input  [10:0] eye2_down         ,          //眼睛下边界    
    input  [10:0] eye2_left         ,          //眼睛左边界
    input  [10:0] eye2_right        ,          //眼睛左边界
    
    output  reg  [10:0]        eye_lock      ,

    //跟踪结果
    output reg [10:0] eye1_up_trk                   ,          //眼睛上边界
    output reg [10:0] eye1_down_trk                 ,          //眼睛下边界 
    output reg [10:0] eye1_left_trk                 ,          //眼睛左边界
    output reg [10:0] eye1_right_trk                ,          //眼睛左边界

    output reg [10:0] eye2_up_trk                   ,          //眼睛上边界
    output reg [10:0] eye2_down_trk                 ,          //眼睛下边界    
    output reg [10:0] eye2_left_trk                 ,          //眼睛左边界
    output reg [10:0] eye2_right_trk                ,          //眼睛左边界   
    
    output  reg[10:0] eye1_high_trk                ,
    output  reg[10:0] eye2_high_trk                ,  
    output  reg[10:0] eye1_wide_trk                ,
    output  reg[10:0] eye2_wide_trk                
    );
reg             eye1_up_get     ;
reg             eye2_up_get     ;    
    
wire [10:0]      px_x    ;          //像素在显示区域的横坐标
wire [10:0]      px_y    ;           //像素在显示区域的纵坐标

wire   image_end  ;           //一帧结束标志
wire   touch_en;

reg    fisrt_time   ;           //第一次跟踪标志，表示需要使用_first坐标

reg    touch_key_d0;
reg    touch_key_d1;



//起始跟踪坐标
reg [10:0]     eye1_up_trk_first    ;         //眼睛上边界
reg [10:0]   eye1_down_trk_first    ;         //眼睛下边界 
reg [10:0]   eye1_left_trk_first    ;         //眼睛左边界
reg [10:0]  eye1_right_trk_first    ;         //眼睛左边界
reg [10:0]     eye2_up_trk_first    ;         //眼睛上边界
reg [10:0]   eye2_down_trk_first    ;         //眼睛下边界    
reg [10:0]   eye2_left_trk_first    ;         //眼睛左边界
reg [10:0]  eye2_right_trk_first    ;         //眼睛左边界
 
//预测下一帧跟踪坐标
reg [10:0]     eye1_up_trk_next    ;         //眼睛上边界
reg [10:0]   eye1_down_trk_next    ;         //眼睛下边界 
reg [10:0]   eye1_left_trk_next    ;         //眼睛左边界
reg [10:0]  eye1_right_trk_next    ;         //眼睛左边界
reg [10:0]     eye2_up_trk_next    ;         //眼睛上边界
reg [10:0]   eye2_down_trk_next    ;         //眼睛下边界    
reg [10:0]   eye2_left_trk_next    ;         //眼睛左边界
reg [10:0]  eye2_right_trk_next    ;         //眼睛左边界   

//当前帧眼睛跟踪坐标中间值
reg [10:0]     eye1_up_trk_tmp    ;         //眼睛上边界
reg [10:0]   eye1_down_trk_tmp    ;         //眼睛下边界 
reg [10:0]   eye1_left_trk_tmp    ;         //眼睛左边界
reg [10:0]  eye1_right_trk_tmp    ;         //眼睛左边界
reg [10:0]     eye2_up_trk_tmp    ;         //眼睛上边界
reg [10:0]   eye2_down_trk_tmp    ;         //眼睛下边界    
reg [10:0]   eye2_left_trk_tmp    ;         //眼睛左边界
reg [10:0]  eye2_right_trk_tmp    ;         //眼睛左边界

//判断帧起与始
assign image_end = ( lcd_pixel_xpos == 700 && lcd_pixel_ypos == 480 ) ? 1'd1 : 1'd0     ;         

//根据按键信号的上升沿判断按下了按键
assign  touch_en = (~touch_key_d1) & touch_key_d0;

//计算像素在图像中的坐标
assign  px_x = lcd_pixel_xpos - 79  ;
assign  px_y = lcd_pixel_ypos       ;


always @ (posedge module_clk or negedge module_rst_n) begin
    if(module_rst_n == 1'b0) begin
        touch_key_d0 <= 1'b0;
        touch_key_d1 <= 1'b0;
    end
    else begin
        touch_key_d0 <= touch_key;
        touch_key_d1 <= touch_key_d0;
    end 
end


//按键按下，确定起始跟踪坐标
always @ (posedge module_clk or negedge module_rst_n) begin
    if(module_rst_n == 1'b0) begin
                    eye_lock <= 1'b11111111111    ;
           eye1_up_trk_first <= 11'd0   ;
         eye1_down_trk_first <= 11'd0   ;
         eye1_left_trk_first <= 11'd0   ;
        eye1_right_trk_first <= 11'd0   ;
           eye2_up_trk_first <= 11'd0   ;
         eye2_down_trk_first <= 11'd0   ;
         eye2_left_trk_first <= 11'd0   ;
        eye2_right_trk_first <= 11'd0   ; 
                  fisrt_time <= 1'd0    ; 
    end
    else if(touch_en)begin
        eye_lock <= 1'd0    ;
           eye1_up_trk_first <= eye1_up      ;
         eye1_down_trk_first <= eye1_down    ;
         eye1_left_trk_first <= eye1_left    ;
        eye1_right_trk_first <= eye1_right   ;     
           eye2_up_trk_first <= eye2_up      ;
         eye2_down_trk_first <= eye2_down    ;
         eye2_left_trk_first <= eye2_left    ;
        eye2_right_trk_first <= eye2_right   ;
                  fisrt_time <= 1'b1    ; 
    end 
    else if(image_end) begin
        fisrt_time <= 1'b0    ; 
    end
end

always @ (posedge module_clk or negedge module_rst_n) begin
    if(module_rst_n == 1'b0) begin
           eye1_up_trk_next <= 11'd0    ;
         eye1_down_trk_next <= 11'd0    ;
         eye1_left_trk_next <= 11'd0    ;
        eye1_right_trk_next <= 11'd0    ;
           eye2_up_trk_next <= 11'd0    ;
         eye2_down_trk_next <= 11'd0    ;
         eye2_left_trk_next <= 11'd0    ;
        eye2_right_trk_next <= 11'd0    ;
        
    end
    
    //每帧结束时确定下一帧跟踪坐标
    else if(image_end) begin
        if(fisrt_time)begin
               eye1_up_trk_next <=    eye1_up_trk_first - 11'd10    ;
             eye1_down_trk_next <=  eye1_down_trk_first + 11'd10    ;
             eye1_left_trk_next <=  eye1_left_trk_first - 11'd10    ;
            eye1_right_trk_next <= eye1_right_trk_first + 11'd10    ;
               eye2_up_trk_next <=    eye2_up_trk_first - 11'd10    ;
             eye2_down_trk_next <=  eye2_down_trk_first + 11'd10    ;
             eye2_left_trk_next <=  eye2_left_trk_first - 11'd10    ;
            eye2_right_trk_next <= eye2_right_trk_first + 11'd10    ;
        end 
        else if(~fisrt_time)begin
               eye1_up_trk_next <=    eye1_up_trk - 11'd10    ;
             eye1_down_trk_next <=  eye1_down_trk + 11'd10    ;
             eye1_left_trk_next <=  eye1_left_trk - 11'd10    ;
            eye1_right_trk_next <= eye1_right_trk + 11'd10    ;
               eye2_up_trk_next <=    eye2_up_trk - 11'd10    ;
             eye2_down_trk_next <=  eye2_down_trk + 11'd10    ;
             eye2_left_trk_next <=  eye2_left_trk - 11'd10    ;
            eye2_right_trk_next <= eye2_right_trk + 11'd10    ;
        end 
    end
end

//眼睛上下跟踪
always @(posedge module_clk  or negedge module_rst_n) begin
    if( !module_rst_n ) begin
    
           eye1_up_trk <= 11'd0    ;
         eye1_down_trk <= 11'd0    ;

           eye2_up_trk <= 11'd0    ;
         eye2_down_trk <= 11'd0    ;

           eye1_up_trk_tmp <= 11'd0    ;
         eye1_down_trk_tmp <= 11'd0    ;

           eye2_up_trk_tmp <= 11'd0    ;
         eye2_down_trk_tmp <= 11'd0    ;
         
               eye1_up_get <= 1'd0  ;
               eye2_up_get <= 1'd0  ;  
               
             eye1_high_trk <= 11'd0  ;
             eye2_high_trk <= 11'd0  ;  
    end      
    else if( px_x >= eye1_left_trk_next && px_x <= eye1_right_trk_next &&  px_y >= eye1_up_trk_next && px_y <= eye1_down_trk_next) begin 
        if(din == 0) begin
            if(eye1_up_get == 0 ) begin
                eye1_up_trk_tmp <= px_y   ;
                eye1_up_get <= 1'd1  ;
            end
            else if(eye1_up_get ==1 ) begin
                eye1_down_trk_tmp <= px_y   ;
            end
        end
    end      
    
    else if( px_x >= eye2_left_trk_next && px_x <= eye2_right_trk_next &&  px_y >= eye2_up_trk_next && px_y <= eye2_down_trk_next) begin 
        if(din == 0) begin
            if(eye2_up_get == 0 ) begin
                eye2_up_trk_tmp <= px_y   ;
                eye2_up_get <= 1'd1  ;
            end
            else if(eye2_up_get ==1 ) begin
                eye2_down_trk_tmp <= px_y   ;
            end
        end
    end  
    
    else if( px_y == 480 && px_x == 1 ) begin
           eye1_up_trk <= eye1_up_trk_tmp    ;
         eye1_down_trk <= eye1_down_trk_tmp    ;
         eye1_high_trk <= eye1_down_trk_tmp - eye1_up_trk_tmp    ;
        
           eye2_up_trk <= eye2_up_trk_tmp    ;
         eye2_down_trk <= eye2_down_trk_tmp    ;
         eye2_high_trk <= eye2_down_trk_tmp - eye2_up_trk_tmp    ;
               eye1_up_get <= 1'd0  ;
               eye2_up_get <= 1'd0  ;  
    end
end 

//眼睛左右边界跟踪
always @(posedge module_clk  or negedge module_rst_n) begin
    if( !module_rst_n ) begin

         eye1_left_trk <= 11'd640    ;
        eye1_right_trk <= 11'd0    ;

         eye2_left_trk <= 11'd640    ;
        eye2_right_trk <= 11'd0    ;
    
         eye1_left_trk_tmp <= 11'd640    ;
        eye1_right_trk_tmp <= 11'd0    ;

         eye2_left_trk_tmp <= 11'd640    ;
        eye2_right_trk_tmp <= 11'd0    ;
        
        eye1_wide_trk <= 11'd0          ;
        eye2_wide_trk <= 11'd0           ;    
        
    end      
    else if( px_x >= eye1_left_trk_next && px_x <= eye1_right_trk_next &&  px_y >= eye1_up_trk_next && px_y <= eye1_down_trk_next) begin 
        if(din == 0) begin
            if(px_x < eye1_left_trk_tmp ) begin
                eye1_left_trk_tmp <= px_x   ;
            end
            else if(px_x > eye1_right_trk_tmp ) begin
                eye1_right_trk_tmp <= px_x   ;
            end
        end
    end      
    
    else if( px_x >= eye2_left_trk_next && px_x <= eye2_right_trk_next &&  px_y >= eye2_up_trk_next && px_y <= eye2_down_trk_next) begin 
        if(din == 0) begin
            if(px_x < eye2_left_trk_tmp ) begin
                eye2_left_trk_tmp <= px_x   ;
            end
            else if(px_x > eye2_right_trk_tmp ) begin
                eye2_right_trk_tmp <= px_x   ;
            end
        end    
    end  
    
    else if( px_y == 480 && px_x == 1 ) begin
          eye1_left_trk <= eye1_left_trk_tmp    ;
         eye1_right_trk <= eye1_right_trk_tmp    ;
          eye1_wide_trk <= eye1_right_trk_tmp - eye1_left_trk_tmp    ;
         
          eye2_left_trk <= eye2_left_trk_tmp    ;
         eye2_right_trk <= eye2_right_trk_tmp    ;
          eye2_wide_trk <= eye2_right_trk_tmp - eye2_left_trk_tmp    ;
         
        eye1_left_trk_tmp <= 11'd640    ;
        eye1_right_trk_tmp <= 11'd0    ;

         eye2_left_trk_tmp <= 11'd640    ;
        eye2_right_trk_tmp <= 11'd0    ;
        
    end
end 
endmodule