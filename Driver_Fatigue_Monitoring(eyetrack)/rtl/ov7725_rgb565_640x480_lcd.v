//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                               
//----------------------------------------------------------------------------------------
// File name:           ov7725_rgb565_640x480_lcd
// Last modified Date:  2018/3/21 13:58:23
// Last Version:        V1.0
// Descriptions:        OV7725摄像头RGB TFT-LCD显示实验
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2018/3/21 13:58:23
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ov7725_rgb565_640x480_lcd(    
    input                 sys_clk     ,  //系统时钟
    input                 sys_rst_n   ,  //系统复位，低电平有效
    //摄像头接口
    input                 cam_pclk    ,  //cmos 数据像素时钟
    input                 cam_vsync   ,  //cmos 场同步信号
    input                 cam_href    ,  //cmos 行同步信号
    input        [7:0]    cam_data    ,  //cmos 数据
    output                cam_rst_n   ,  //cmos 复位信号，低电平有效
    output                cam_sgm_ctrl,  //cmos 时钟选择信号, 1:使用摄像头自带的晶振
    output                cam_scl     ,  //cmos SCCB_SCL线
    inout                 cam_sda     ,  //cmos SCCB_SDA线
    //SDRAM接口
    output                sdram_clk   ,  //SDRAM 时钟
    output                sdram_cke   ,  //SDRAM 时钟有效
    output                sdram_cs_n  ,  //SDRAM 片选
    output                sdram_ras_n ,  //SDRAM 行有效
    output                sdram_cas_n ,  //SDRAM 列有效
    output                sdram_we_n  ,  //SDRAM 写有效
    output       [1:0]    sdram_ba    ,  //SDRAM Bank地址
    output       [1:0]    sdram_dqm   ,  //SDRAM 数据掩码
    output       [12:0]   sdram_addr  ,  //SDRAM 地址
    inout        [15:0]   sdram_data  ,  //SDRAM 数据    
    //lcd接口                          
    output                lcd_hs      ,  //LCD 行同步信号
    output                lcd_vs      ,  //LCD 场同步信号
    output                lcd_de      ,  //LCD 数据输入使能
    output       [15:0]   lcd_rgb     ,  //LCD RGB565颜色数据
    output                lcd_bl      ,  //LCD 背光控制信号
    output                lcd_rst     ,  //LCD 复位信号
    output                lcd_pclk    ,  //LCD 采样时钟
    output                beep ,

    input        touch_key    //触摸按键         
    );

//parameter define
parameter  SLAVE_ADDR = 7'h21         ;  //OV7725的器件地址7'h21
parameter  BIT_CTRL   = 1'b0          ;  //OV7725的字节地址为8位  0:8位 1:16位
parameter  CLK_FREQ   = 26'd33_333_333;  //i2c_dri模块的驱动时钟频率 33.3MHz
parameter  I2C_FREQ   = 18'd250_000   ;  //I2C的SCL时钟频率,不超过400KHz
parameter  CMOS_H_PIXEL = 24'd640     ;  //CMOS水平方向像素个数,用于设置SDRAM缓存大小
parameter  CMOS_V_PIXEL = 24'd480     ;  //CMOS垂直方向像素个数,用于设置SDRAM缓存大小

//wire define
wire                  clk_100m        ;  //100mhz时钟,SDRAM操作时钟
wire                  clk_100m_shift  ;  //100mhz时钟,SDRAM相位偏移时钟
wire                  cam_pclk_div    ;  //像素时钟信号分频
wire                  clk_33_3m       ;  //33.3mhz时钟,提供给lcd驱动时钟
wire                  locked          ;
wire                  rst_n           ;
                                      
wire                  i2c_exec        ;  //I2C触发执行信号
wire   [15:0]         i2c_data        ;  //I2C要配置的地址与数据(高8位地址,低8位数据)          
wire                  cam_init_done   ;  //摄像头初始化完成
wire                  i2c_done        ;  //I2C寄存器配置完成信号
wire                  i2c_dri_clk     ;  //I2C操作时钟
                                 
wire                  wr_en           ;  //sdram_ctrl模块写使能
wire   [15:0]         wr_data         ;  //sdram_ctrl模块写数据
wire                  rd_en           ;  //sdram_ctrl模块读使能
wire   [15:0]         rd_data         ;  //sdram_ctrl模块读数据
wire                  sdram_init_done ;  //SDRAM初始化完成
wire                  sys_init_done   ;  //系统初始化完成(sdram初始化+摄像头初始化)

                                                            
wire  [11:0]       face_left          ;  //脸左边界
wire  [11:0]       face_right         ;  //脸左边界
wire  [11:0]       face_up            ;  //脸上边界
wire  [11:0]       face_down          ;  //脸下边界
wire  [11:0]       face_widest_r      ;  //脸b部最宽行

wire   [10:0]      eye1_up            ;  //眼睛上边界
wire   [10:0]      eye1_down          ;  //眼睛下边界  
wire   [10:0]      eye1_left          ;  //眼睛左边界          
wire   [10:0]      eye1_right         ;  //眼睛左边界 
                                         
wire   [10:0]      eye2_up            ;  //眼睛上边界
wire   [10:0]      eye2_down          ;  //眼睛下边界  
wire   [10:0]      eye2_left          ;  //眼睛左边界          
wire   [10:0]      eye2_right         ;  //眼睛左边界  
//
//wire   [10:0]       eye1_high           ;
//wire   [10:0]       eye2_high           ;   
//wire   [10:0]       eye1_wide           ;
//wire   [10:0]       eye2_wide           ;   
wire   [10:0]       eye_lock      ;
wire   [10:0]       eye1_high_trk           ;
wire   [10:0]       eye2_high_trk           ;   
wire   [10:0]       eye1_wide_trk           ;
wire   [10:0]       eye2_wide_trk           ;   

wire   [10:0] eye1_up_trk                   ;          //眼睛上边界
wire   [10:0] eye1_down_trk                 ;          //眼睛下边界 
wire   [10:0] eye1_left_trk                 ;          //眼睛左边界
wire   [10:0] eye1_right_trk                ;          //眼睛左边界

wire   [10:0] eye2_up_trk                   ;          //眼睛上边界
wire   [10:0] eye2_down_trk                 ;          //眼睛下边界    
wire   [10:0] eye2_left_trk                 ;          //眼睛左边界
wire   [10:0] eye2_right_trk                ;          //眼睛左边界    
      
//需管理的信号
wire                 lcd_rd_en         ;   //lcd读请求
wire  [10:0]         lcd_pixel_xpos    ;   //lcd正在显示的像素的横坐标
wire  [10:0]         lcd_pixel_ypos    ;   //lcd正在显示的像素的纵坐标
wire                 morph_wr_en       ;   //morph_1D模块写请求
wire                 morph_face_wr_en  ;   //morph_1D模块写请求

wire                 rgb2gray_rd_en    ;   //rgb2gray模块读请求
wire                 rgb2gray_wr_en    ;   //rgb2gray模块写请求
wire  [23:0]         rd_addr           ;   //读起始地址
wire  [23:0]         wr_addr           ;   //写起始地址
wire                 cmos_frame_href   ;   //行同步信号
wire                 cmos_frame_vsync  ;   //场同步信号
wire                 cam_href_r        ;   //行同步信号
wire                 cam_vsync_r       ;   //场同步信号
wire                 cmos_wr_en        ;   //摄像头模块写使能
wire  [15:0]         cmos_wr_data      ;   //相机输出数据
wire  [7:0]          dout_binary8b     ;   //rgb2black模块输出数据
wire                 dout_binary1b     ;   //rgb2black模块输出数据
wire  [7:0]          dout_binary8b_face;   //rgb2black模块输出数据
wire                 dout_binary1b_face;   //rgb2black模块输出数据
wire   [7:0]         dout_morph_face   ;   //不保留细节的形态学模块输出到人脸定位

//*****************************************************
//**                    main code
//*****************************************************

assign  rst_n = sys_rst_n & locked;
//系统初始化完成：SDRAM和摄像头都初始化完成
//避免了在SDRAM初始化过程中向里面写入数据
assign  sys_init_done = sdram_init_done & cam_init_done;
//不对摄像头硬件复位,固定高电平
assign  cam_rst_n = 1'b1;
//cmos 时钟选择信号, 1:使用摄像头自带的晶振
assign  cam_sgm_ctrl = 1'b1;

//锁相环
pll_clk u_pll_clk(
    .areset       (~sys_rst_n),
    .inclk0       (sys_clk),
    .c0           (clk_100m),
    .c1           (clk_100m_shift),
    .c2           (clk_33_3m),
    .locked       (locked)
    );

//I2C配置模块    
i2c_ov7725_rgb565_cfg u_i2c_cfg(
    .clk           (i2c_dri_clk),
    .rst_n         (rst_n),
    .i2c_done      (i2c_done),
    .i2c_exec      (i2c_exec),
    .i2c_data      (i2c_data),
    .init_done     (cam_init_done)
    );    

//I2C驱动模块
i2c_dri 
   #(
    .SLAVE_ADDR  (SLAVE_ADDR),               //参数传递
    .CLK_FREQ    (CLK_FREQ  ),              
    .I2C_FREQ    (I2C_FREQ  )                
    ) 
   u_i2c_dri(
    .clk         (clk_33_3m   ),   
    .rst_n       (rst_n     ),   
    //i2c interface
    .i2c_exec    (i2c_exec  ),   
    .bit_ctrl    (BIT_CTRL  ),   
    .i2c_rh_wl   (1'b0),                     //固定为0，只用到了IIC驱动的写操作   
    .i2c_addr    (i2c_data[15:8]),   
    .i2c_data_w  (i2c_data[7:0]),   
    .i2c_data_r  (),   
    .i2c_done    (i2c_done  ),   
    .scl         (cam_scl   ),   
    .sda         (cam_sda   ),   
    //user interface
    .dri_clk     (i2c_dri_clk)               //I2C操作时钟
);

//CMOS图像数据采集模块
cmos_capture_data u_cmos_capture_data(
    .rst_n               (rst_n & sys_init_done), //系统初始化完成之后再开始采集数据 
    .cam_pclk            (cam_pclk),
    .cam_vsync           (cam_vsync),
    .cam_href            (cam_href),
    .cam_data            (cam_data),         
    .cmos_frame_vsync    (cmos_frame_vsync),
    .cmos_frame_href     (cmos_frame_href),
    .cmos_frame_valid    (cmos_wr_en),            //数据有效使能信号
    .cmos_frame_data     (cmos_wr_data),          //有效数据 

    );

//SDRAM 控制器顶层模块,封装成FIFO接口
//SDRAM 控制器地址组成: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
sdram_top u_sdram_top(
 .ref_clk      (clk_100m),                   //sdram 控制器参考时钟
 .out_clk      (clk_100m_shift),             //用于输出的相位偏移时钟
 .rst_n        (rst_n),                      //系统复位
                                             
  //用户写端口                                  
 .wr_clk       (cam_pclk),                   //写端口FIFO: 写时钟
 .wr_en        (morph_wr_en),                      //写端口FIFO: 写使能
 .wr_data      (wr_data),                    //写端口FIFO: 写数据
 .wr_min_addr  (24'd0),                          //**写SDRAM的起始地址
 .wr_max_addr  (CMOS_H_PIXEL*CMOS_V_PIXEL),                     //写SDRAM的结束地址
 .wr_len       (10'd512),                    //写SDRAM时的数据突发长度
 .wr_load      (~rst_n),                     //写端口复位: 复位写地址,清空写FIFO
                                             
  //用户读端口                                  
 .rd_clk       (clk_33_3m),                  //读端口FIFO: 读时钟
 .rd_en        (lcd_rd_en),          //读端口FIFO: 读使能,rd_en为图像处理模块读信号，lcd_rd_en为lcd读信号
 .rd_data      (rd_data),                    //读端口FIFO: 读数据
 .rd_min_addr  (24'd0),                          //**读SDRAM的起始地址
 .rd_max_addr  (CMOS_H_PIXEL*CMOS_V_PIXEL),                     //读SDRAM的结束地址
 .rd_len       (10'd512),                    //从SDRAM中读数据时的突发长度
 .rd_load      (~rst_n),                     //读端口复位: 复位读地址,清空读FIFO
                                             
 //用户控制端口                                
 .sdram_read_valid  (1'b1),                  //SDRAM 读使能
 .sdram_pingpang_en (1'b1),                  //SDRAM 乒乓操作使能
 .sdram_init_done (sdram_init_done),         //SDRAM 初始化完成标志
                                             
 //SDRAM 芯片接口                                
 .sdram_clk    (sdram_clk),                  //SDRAM 芯片时钟
 .sdram_cke    (sdram_cke),                  //SDRAM 时钟有效
 .sdram_cs_n   (sdram_cs_n),                 //SDRAM 片选
 .sdram_ras_n  (sdram_ras_n),                //SDRAM 行有效
 .sdram_cas_n  (sdram_cas_n),                //SDRAM 列有效
 .sdram_we_n   (sdram_we_n),                 //SDRAM 写有效
 .sdram_ba     (sdram_ba),                   //SDRAM Bank地址
 .sdram_addr   (sdram_addr),                 //SDRAM 行/列地址
 .sdram_data   (sdram_data),                 //SDRAM 数据
 .sdram_dqm    (sdram_dqm)                   //SDRAM 数据掩码
    );


//LCD驱动显示模块
lcd_rgb_top  u_lcd_rgb_top(
    .lcd_clk      (clk_33_3m),         
    .sys_rst_n    (rst_n),
    .lcd_hs       (lcd_hs),
    .lcd_vs       (lcd_vs),
    .lcd_de       (lcd_de),
    .lcd_rgb      (lcd_rgb),
    .lcd_bl       (lcd_bl),
    .lcd_rst      (lcd_rst),
    .lcd_pclk     (lcd_pclk),
    .face_left    (face_left)    ,          //脸左边界
    .face_right   (face_right)    ,          //脸左边界
    .face_up      (face_up)    ,          //脸上边界
    .face_down    (face_down)  ,             //脸下边界   
    .face_widest_r(face_widest_r),        //脸最宽的行 
    
    .eye1_up            (eye1_up),
    .eye1_down          (eye1_down),
    .eye1_left          (eye1_left),
    .eye1_right         (eye1_right),  
    
    .eye2_up            (eye2_up),
    .eye2_down          (eye2_down),
    .eye2_left          (eye2_left),
    .eye2_right         (eye2_right),
    
    .eye1_up_trk            (eye1_up_trk),
    .eye1_down_trk          (eye1_down_trk),
    .eye1_left_trk          (eye1_left_trk),
    .eye1_right_trk         (eye1_right_trk), 
    
    .eye2_up_trk            (eye2_up_trk),
    .eye2_down_trk          (eye2_down_trk),
    .eye2_left_trk          (eye2_left_trk),
    .eye2_right_trk         (eye2_right_trk),
    
    .cmos_data    ({rd_data[7:3],rd_data[7:2],rd_data[7:3]}),   //拼接为RGB565格式
    .data_req     (lcd_rd_en),
    
    .pixel_xpos_w (lcd_pixel_xpos),
    .pixel_ypos_w (lcd_pixel_ypos),
    
    .eye_lock       (eye_lock)
    );


//RGB转灰度及二值化模块
rgb2black u_rgb2black(
    
    .module_clk         (cam_pclk),             //读数据时钟
    .module_rst_n       (rst_n),                //低电平复位信号
    .data_val           (cmos_wr_en),           //相机数据是否有效
    .din                (cmos_wr_data),         //输入相机数据
    
    .rgb2black_wr_en    (rgb2gray_wr_en),       //发出写SDRAM请求
    .dout_gray          (),                     //灰度数据
    .dout_binary8b      (),           //二值数据
    .dout_binary1b      (dout_binary1b) ,          //二值数据
    
    .dout_binary8b_face (),           //二值数据
    .dout_binary1b_face (dout_binary1b_face)           //二值数据    
    
    );

//保留细节的形态学模块    
morph u_morph(
    .module_clk         (cam_pclk_div),         //数据入栈驱动时钟
    .module_clk2        (cam_pclk),             //模块工作时钟
    .module_rst_n       (rst_n),
    
    .cam_href           (cam_href),             //摄像头行同步信号，用于复位计数器
    .cam_vsync          (cam_vsync),            //场同步信号
    .din_val            (rgb2gray_wr_en),
    .din                (dout_binary1b),
    
    .cam_href_r         (cam_href_r),          //行同步信号   
    .cam_vsync_r        (cam_vsync_r),         //场同步信号      
    .morph_wr_en        (morph_wr_en),
    .dout_CRS8b         (wr_data[7:0]),                     //腐蚀数据     
    .dout_EPS8b         (),              //膨胀数据
    .dout_CRS1b         (),                     //腐蚀数据     
    .dout_EPS1b         ()                      //膨胀数据      
);

//不保留细节的二值化图像形态学模块    
morph u_morph_face(
    .module_clk         (cam_pclk_div),         //数据入栈驱动时钟
    .module_clk2        (cam_pclk),             //模块工作时钟
    .module_rst_n       (rst_n),
    
    .cam_href           (cam_href),             //摄像头行同步信号，用于复位计数器
    .cam_vsync          (cam_vsync),            //场同步信号
    .din_val            (rgb2gray_wr_en),
    .din                (dout_binary1b_face),
    
    .cam_href_r         (),          //行同步信号   
    .cam_vsync_r        (),         //场同步信号      
    .morph_wr_en        (morph_face_wr_en),
    .dout_CRS8b         (dout_morph_face),                     //腐蚀数据     
//    .morph_wr_en        (morph_wr_en),
//    .dout_CRS8b         (wr_data),                     //腐蚀数据    
    .dout_EPS8b         (),              //膨胀数据
    .dout_CRS1b         (),                     //腐蚀数据     
    .dout_EPS1b         ()                      //膨胀数据      
);

face_pst u_face_pst(
    .module_clk         (cam_pclk_div),         //数据入栈驱动时钟
    .module_clk2        (cam_pclk),             //模块工作时钟
    .module_rst_n       (rst_n),
    
    .cam_href           (cam_href_r),             //摄像头行同步信号，用于复位计数器
    .cam_vsync          (cam_vsync_r),            //场同步信号
    .din_val            (morph_face_wr_en),
    .din                (dout_morph_face[0]),
//    .din_val            (morph_wr_en),
//    .din                (wr_data),
    .face_left          (face_left)    ,          //脸左边界
    .face_right         (face_right)    ,          //脸左边界
    .face_up            (face_up)    ,          //脸上边界
    .face_down          (face_down)  ,             //脸下边界
    .face_widest_r      (face_widest_r)          //脸最宽的行  

);

eye_pst u_eye_pst(
    .module_clk         (clk_33_3m),         //数据入栈驱动时钟
    .module_rst_n       (rst_n),
    
    .din_val            (lcd_rd_en),
    .din                (rd_data[0]),
    .lcd_pixel_xpos     (lcd_pixel_xpos),
    .lcd_pixel_ypos     (lcd_pixel_ypos),
    .face_left          (face_left)    ,         //脸左边界
    .face_right         (face_right)    ,        //脸左边界
    .face_up            (face_up)    ,           //脸上边界
    .face_widest_r      (face_widest_r)  ,       //脸最宽的行  
    
    .eye1_up            (eye1_up),
    .eye1_down          (eye1_down),
    .eye1_left          (eye1_left),
    .eye1_right         (eye1_right),  
    
    .eye2_up            (eye2_up),
    .eye2_down          (eye2_down),
    .eye2_left          (eye2_left),
    .eye2_right         (eye2_right) 
    
//    .eye1_high          (eye1_high),
//    .eye2_high          (eye2_high),
//    .eye1_wide          (eye1_wide),
//    .eye2_wide          (eye2_wide)
);

eye_track u_eye_track(
    .module_clk         (clk_33_3m),         //数据入栈驱动时钟
    .module_rst_n       (rst_n), 
    .touch_key          (touch_key),    //触摸按键  
 
    .din_val            (lcd_rd_en),
    .din                (rd_data[0]),
    .lcd_pixel_xpos     (lcd_pixel_xpos),
    .lcd_pixel_ypos     (lcd_pixel_ypos),
    
    .eye1_up            (eye1_up),
    .eye1_down          (eye1_down),
    .eye1_left          (eye1_left),
    .eye1_right         (eye1_right),  
    
    .eye2_up            (eye2_up),
    .eye2_down          (eye2_down),
    .eye2_left          (eye2_left),
    .eye2_right         (eye2_right),
    
    
    .eye1_up_trk        (eye1_up_trk),
    .eye1_down_trk      (eye1_down_trk),
    .eye1_left_trk      (eye1_left_trk),
    .eye1_right_trk     (eye1_right_trk), 
    
    .eye2_up_trk        (eye2_up_trk),
    .eye2_down_trk      (eye2_down_trk),
    .eye2_left_trk      (eye2_left_trk),
    .eye2_right_trk     (eye2_right_trk),
    
    .eye1_high_trk      (eye1_high_trk),
    .eye2_high_trk      (eye2_high_trk),
    .eye1_wide_trk      (eye1_wide_trk),
    .eye2_wide_trk      (eye2_wide_trk),
    .eye_lock       (eye_lock)

);
perclos_calibrate u_perclos_calibrate(
    .module_clk         (clk_33_3m),
    .module_rst_n       (rst_n),
    .lcd_pixel_xpos     (lcd_pixel_xpos),
    .lcd_pixel_ypos     (lcd_pixel_ypos),

    .eye1_high          (eye1_high_trk),
    .eye2_high          (eye2_high_trk),
    .eye1_wide          (eye1_wide_trk),
    .eye2_wide          (eye2_wide_trk),
    .beep               (beep)
    );
    
//分频器模块
freq_div u_freq_div(
    .freq_in            (cam_pclk),             //输入频率
    
    .freq_out           (cam_pclk_div)          //输出频率
    );
endmodule