module perclose(
    input   module_clk,
    input   module_rst_n,
    input  [10:0]lcd_pixel_xpos,          
    input  [10:0]lcd_pixel_ypos,          
    
    input  [10:0]eye1_high,
    input  [10:0]eye2_high,
    input  [10:0] eye1_Wide                 ,
    input  [10:0] eye2_Wide                 

    );
    
reg [8:0]   v_cnt   ;           //记录场值
reg [21:0]  eye_2v  ;
reg          eye_close_done     ;        //闭眼过程结束标志
reg [329:0]  eye_inclose     ;           //记录闭眼过程每帧大小
reg [8:0]   eye_inclose_cnt  ;           //闭眼过程帧数记录

reg [329:0]  eye_inopen      ;           //记录睁眼过程每帧大小
reg [8:0]   eye_inopen_cnt   ;          //睁眼过程帧数记录
reg  [1:0] state    ;

//************************眼睛睁闭过程比例法**************************//
//存储两帧眼睛大小值
always @( posedge module_clk  or negedge module_rst_n ) begin
    if( !module_rst_n ) begin
        eye_2v <= 22'd0   ;
    end     
    
    else if( lcd_pixel_xpos == 1 && lcd_pixel_ypos == 1 )begin
        eye_2v <= { eye_2v[10:0],eye1_high }    ;
    end
end 

//记录闭眼与睁眼所经历的帧数
always @( posedge module_clk  or negedge module_rst_n ) begin
    if( !module_rst_n ) begin
        v_cnt <= 9'd0   ;
    end     
    
    //睁闭的过程中每帧数一次
    else if( lcd_pixel_xpos == 3 && lcd_pixel_ypos == 1 && state != 0 )begin
        v_cnt <= v_cnt +1    ;
    end
    
    //没有睁闭眼，计数器置零
    else if(state == 2) begin
        v_cnt <= 9'd0   ;
    end
end 

//睁闭眼状态转换
always @( posedge module_clk  or negedge module_rst_n ) begin
    if( !module_rst_n ) begin
        state <= 2'd0   ;
    end
    
    else if( lcd_pixel_xpos == 3 && lcd_pixel_ypos == 1 )begin
        if(eye_2v[10:0] < eye_2v[21:10] && state == 0 ) begin
            state <= 1   ;       //眼睛变小，进入闭眼过程
            
        end
        else if(eye_2v[10:0] > eye_2v[21:10] && state == 1 && eye_inclose_cnt <= 8 ) begin
            state <= 0   ;       //眼睛变小后开始变大，但变小过程没有持续8帧，认为之前并不是闭眼
        end
        else if(eye_2v[10:0] > eye_2v[21:10] &&  state == 1 && eye_inopen_cnt > 8) begin
            state <= 2   ;          //闭眼过程完成，进入睁眼过程
        end
        
    end
end 

//睁闭眼过程记录
always @( posedge module_clk  or negedge module_rst_n ) begin
    if( !module_rst_n ) begin
        eye_inclose <= 330'd0   ;
        eye_inopen <= 330'd0    ;
        eye_inclose_cnt <= 9'd0 ;
        eye_inopen_cnt <= 9'd0  ;
        eye_close_done <= 1'd0  ;
    end
    
    else if( lcd_pixel_xpos == 3 && lcd_pixel_ypos == 1 )begin
        if( state == 1 && eye_close_done == 0) begin
            eye_inclose <= {eye_inclose[299:0],eye_2v[10:0]}  ;       //眼睛闭眼过程中，存储每帧眼镜的大小
            eye_inclose_cnt <= eye_inclose_cnt + 1  ;
        end
        else if( state == 2 ) begin
            eye_inopen <= {eye_inopen[299:0],eye_2v[10:0]}  ;       //眼睛闭眼过程中，存储每帧眼镜的大小
            eye_inopen_cnt <= eye_inopen_cnt + 1    ;
        end
        else if( state != 1) begin
            eye_close_done <= 1'd1   ;       //眼睛闭眼过程中，存储每帧眼镜的大小
        end
        
    end
end 



endmodule