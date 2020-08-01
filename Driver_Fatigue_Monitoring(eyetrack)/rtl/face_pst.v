module face_pst(
    input module_clk                            ,          //模块工作时钟
    input module_clk2                           ,          //模块打拍时钟
    input module_rst_n                          ,          //模块复位时钟
    input cam_href                              ,          //行同步信号，用于复位计数器
    input cam_vsync                             ,          //场同步信号
        
    input din_val                               ,          //数据有效信号
    input din                                   ,          //输入数据

    output  reg[11:0]       face_left           ,          //脸左边界
    output  reg[11:0]       face_right          ,          //脸左边界
    output  reg[11:0]       face_up             ,          //脸上边界
    output  reg[11:0]       face_down           ,          //脸下边界
    output  reg[11:0]       face_widest_r                  //脸最宽的行
);

//****************锁定信号***************//
reg           r_sta_lock            ;           //行投影结果锁定
reg           face_up_lock          ;           //人脸上边界锁定
reg           face_up_lock_tmp      ;           //人脸上边界锁定
reg           face_left_tmp_lock    ;

//*************************************//

//*************行同步信号打拍************//

reg           cam_href_r0   ;
reg           cam_href_r1   ;

//*************************************//

//*************场同步信号打拍************//

reg           cam_vsync_r0  ;
reg           cam_vsync_r1  ;

//*************************************//

//*****************投影*****************//

reg  [11:0]        rsta_tmp       ;          //行方向统计值
reg  [11:0]        rsta_tmp_max   ;          //行方向统计值
reg  [11:0]        rsta_tmp_r     ;          //行方向统计值
reg  [11:0]        lsta_tmp       ;          //垂直方向统计值   
reg                r_sta          ;          //行投影
reg  [11:0]        r_sta_1cnt     ;          //行投影结果中1的个数

//************数据有效信号打拍***********//

//**************边界中间值**************//

reg  [11:0]       face_left_tmp         ;          //脸左边界
reg  [11:0]       face_right_tmp        ;          //脸左边界
reg  [11:0]       face_left_tmp_min     ;          //脸左边界最小值
reg  [11:0]       face_right_tmp_max    ;          //脸左边界最大值
reg  [11:0]       face_up_tmp           ;          //脸上边界
reg  [11:0]       face_down_tmp         ;          //脸下边界
reg  [11:0]       face_widest_r_tmp     ;          //脸最宽的行

//************数据有效信号打拍***********//

//**************计数器及复位*************//

reg [11:0]    cnt_r         ;           //行计数
reg [11:0]    cnt_l         ;           //列计数
wire          cnt_rrst      ;           //行计数器复位
wire          cnt_lrst      ;           //列计数器复位
wire          cam_href_neg  ;           //行同步信号下降沿

//**************************************//

//检测cam_href上升沿
assign cnt_lrst = (~cam_href_r1) & (cam_href_r0)        ;
    
//检测cam_href下降沿
assign cam_href_neg = (cam_href_r1) & (~cam_href_r0)    ;

//检测cam_vsync上升沿 
assign cnt_rrst = (~cam_vsync_r1) & (cam_vsync_r0)      ;

//************************信号打拍*************************//

//行同步信号打一拍
always @(posedge module_clk or negedge module_rst_n) begin
    if(!module_rst_n) begin
        cam_href_r0 <= 1'b0    ;
        cam_href_r1 <= 1'b0    ;
    end
    
    else begin
        cam_href_r0 <= cam_href       ;
        cam_href_r1 <= cam_href_r0    ;
    end
end

//场同步信号打一拍
always @(posedge module_clk or negedge module_rst_n) begin
    if(!module_rst_n) begin
        cam_vsync_r0 <= 1'b0    ;
        cam_vsync_r1 <= 1'b0    ;
    end
    
    else begin
        cam_vsync_r0 <= cam_vsync       ;
        cam_vsync_r1 <= cam_vsync_r0    ;
    end
end

//列计数模块
always @(posedge module_clk or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        cnt_l <= 12'd0    ;
    end      
    else if( cnt_lrst == 1 ) begin
        cnt_l <= 0    ;  
    end     
    else begin
        cnt_l <= cnt_l + 12'd1    ;  
    end
end 

//行计数模块
always @(posedge module_clk or negedge module_rst_n) begin
    if( !module_rst_n ) begin
        cnt_r <= 12'd0    ;
    end   
    else if(cnt_rrst ) begin             //检测到场同步信号上升沿，计数器置零
        cnt_r <= 12'd0    ;   
    end
    else if(cnt_lrst) begin              //检测等到行同步信号上升沿，计数器加1
        cnt_r <= cnt_r + 12'd1    ; 
    end
end 

//行统计
always @(posedge module_clk or negedge module_rst_n) begin
    if( !module_rst_n ) begin 
        rsta_tmp   <= 12'd0    ;
        r_sta      <= 1'b0     ;
        r_sta_lock <= 1'b0     ;
    end
        
    else if(din == 1 && cnt_lrst != 1) begin
        rsta_tmp <= rsta_tmp + 1    ;        
        
        if(rsta_tmp >= 200 && r_sta_lock == 0) begin            //若一行有>=300个连续白色像素，则r_sta置1，并锁定r_sta
            r_sta <= 1             ;
            r_sta_lock <= 1'b1     ;
        end  
    end
    else if(din != 1 || cnt_lrst == 1 ) begin             
        rsta_tmp <= 12'd0    ;                                  //新行到来或白色像素中断，计数器置零
        if(cnt_lrst == 1 ) begin
            r_sta_lock <= 0     ;                               //新行到来，r_sta解锁
            r_sta <= 0          ;
        end
    end
end    

//行统计打一拍，因face_left_tmp_lock状态判断晚rsta_tmp一拍
always @(posedge module_clk or negedge module_rst_n) begin
    if( !module_rst_n ) begin 
        rsta_tmp_r <= 12'd0   ;
    end       
    else begin
        rsta_tmp_r <= rsta_tmp   ; 
    end
end    

//脸上下边界定位
always @(posedge module_clk or negedge module_rst_n) begin
    if( !module_rst_n ) begin 
        r_sta_1cnt       <= 12'd0   ;
        face_up          <= 12'd0   ;
        face_up_tmp      <= 12'd0   ;
        face_up_lock     <= 1'b0    ; 
        face_up_lock_tmp <= 1'b0    ;           
    end
        
    else if(cnt_l == 642) begin
        if(r_sta == 1 ) begin
            r_sta_1cnt <= r_sta_1cnt + 1   ;                //人脸区域行计数器+1
            
            if(face_up_lock_tmp == 0 && face_up_lock == 0) begin
                face_up_tmp <= cnt_r     ;                  //若人脸上边界处于可重置状态，则将当前行赋值为人脸上边界
                face_up_lock_tmp <= 1    ;                  //人脸上边界更新后，锁定信号置零，临时锁定上边界
            end
            if(r_sta_1cnt >= 50) begin                     //若有超过200行符合要求，则锁定人脸上下边界
                face_up_lock <= 1                 ;
                face_up <= face_up_tmp - 3        ;
                face_down <= face_up_tmp + 347    ;
            end
        end
        
        else if(r_sta == 0 ) begin                          //人脸行中断，计数器复位
            r_sta_1cnt <= 0    ;
            
            if( r_sta_1cnt < 200) begin                     //若符合要求的行数少于要求，则认为所选边界非人脸边界，人脸边界解锁
                face_up_lock_tmp <= 0    ;
            end
        end
    end
    
    else if(cnt_r == 480 && cam_href == 0) begin            //一帧结束，脸上边界解锁，计数器复位
        face_up_lock <= 0        ;
        face_up_lock_tmp <= 0    ;
        r_sta_1cnt <= 12'd0      ;
    end
end  

//寻找脸左右边界  
always @(posedge module_clk or negedge module_rst_n) begin
    if( !module_rst_n ) begin 
        face_left_tmp      <= 12'd0      ;
        face_right_tmp     <= 12'd0      ;
        face_left_tmp_min  <= 12'd640    ;
        face_right_tmp_max <= 12'd0      ;
        face_left_tmp_lock <= 0          ;      
    end  
 
    else if(cnt_l != 642 && cnt_r != 480 && cam_href != 0) begin
    
        if(din == 1 ) begin  
        
            //face_left_tmp为可赋值状态时，在输入像素为白色像素时将列坐标设置为临时左边界，并锁定  
            if(face_left_tmp_lock == 0) begin                   
                face_left_tmp <= cnt_l      ;                
                face_left_tmp_lock <= 1     ;
            end
            
            //face_left_tmp为不可赋值状态时，表示已确定左边界，因此将当前列坐标设置为右边界
            if(face_left_tmp_lock == 1 ) begin                  
                face_right_tmp <= cnt_l     ;
            end
        end
        
        else if(din == 0) begin
        
            //检测到黑像素，若连续白色像素少于预设值，认为此区域不为人脸，解锁边界
            if( rsta_tmp_r < 200 ) begin                        
                face_left_tmp_lock <= 0     ;
            end  
            
            //检测到黑像素且连续白色像素多于预设值，则将临时值赋值给最左边界，最右边界
            else if(rsta_tmp_r >= 200 && face_left_tmp_lock == 1) begin               
                face_left_tmp_min  <= (face_left_tmp  < face_left_tmp_min)  ? face_left_tmp   : face_left_tmp_min     ;
                face_right_tmp_max <= (face_right_tmp > face_right_tmp_max) ? face_right_tmp  : face_right_tmp_max    ;
            end
        end
    end
    
    else if( cnt_l == 642 && cnt_r != 480) begin                //每行结束时解锁边界
        face_left_tmp_lock <= 0     ;
    end 
    
    else if(cnt_r == 480 && cam_href_neg == 1) begin            //一帧结束，得出最终边界，并重置最大最小值
        face_left  <= face_left_tmp_min      ;
        face_right <= face_right_tmp_max     ; 
        face_left_tmp_min  <= 12'd640        ;
        face_right_tmp_max <= 12'd0          ; 
    end 
end  

//脸部最宽处
always @(posedge module_clk or negedge module_rst_n) begin
    if( !module_rst_n ) begin 
        rsta_tmp_max  <= 12'd0        ;
        face_widest_r_tmp <= 12'd0    ;       
    end
        
    else if(cnt_r != 480 && ( rsta_tmp_r > rsta_tmp_max && cnt_r < face_down && cnt_r > face_up) ) begin
        rsta_tmp_max <= rsta_tmp_r     ;
        face_widest_r_tmp <= cnt_r     ;
    end
    else if(cnt_r == 480 && cam_href_neg == 1) begin            //一帧结束，得出最终最宽处
        face_widest_r <= face_widest_r_tmp     ;
        face_widest_r_tmp <= 12'd0             ;  
        rsta_tmp_max  <= 12'd0        ;
     
    end 
end  


endmodule