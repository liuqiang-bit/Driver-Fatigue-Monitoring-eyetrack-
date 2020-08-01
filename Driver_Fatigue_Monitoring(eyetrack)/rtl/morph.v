module morph (

    input   module_clk                  ,           //系统时钟
    input   module_clk2                 ,           //打拍时钟
    input   cam_href                    ,           //行同步信号，用于复位计数器
    input   cam_vsync                   ,           //场同步信号
    input   module_rst_n                ,           //系统服务信号
    
    input   din_val                     ,           //输入数据有效标志
    input   din                         ,           //输入的数据a   
    
    output                  cam_href_r    ,           //行同步信号
    output                 cam_vsync_r    ,           //场同步信号
    output                 morph_wr_en    ,           //SDRAM写请求信号
    output      [7:0]       dout_EPS8b    ,           //膨胀数据
    output      [7:0]       dout_CRS8b    ,           //膨胀数据
    output                  dout_EPS1b    ,           //膨胀数据
    output                  dout_CRS1b                //膨胀数据    
    
 
    );

//************行同步信号传递************//

wire        cam_href_r1    ;       
wire        cam_href_r2    ;       
         
//*************************************// 

//************场同步信号传递************//

wire        cam_vsync_r1    ;       
wire        cam_vsync_r2    ;            
         
//*************************************// 
   
//*************膨胀结果传递*************//

wire        dout_EPS1b1    ;          
         
//*************************************// 
        
//*************腐蚀结果传递*************//

wire        dout_CRS1b1    ;           

//*************************************// 

//*************数据有效信号传递*********//

wire        morph_wr_en1    ;               

//*************************************// 
assign cam_href_r  = cam_href_r2 ;
assign cam_vsync_r = cam_vsync_r2 ;

//*****************腐蚀1****************//   
      
//一维行形态学模块    
morph_row u1_morph_row(
    .module_clk         (module_clk),           //数据入栈驱动时钟
    .module_clk2        (module_clk2),          //模块工作时钟
    .module_rst_n       (module_rst_n),
    
    .cam_href           (cam_href),             //摄像头行同步信号，用于复位计数器
    .cam_vsync          (cam_vsync),        
    .EPS_CRS            (1'd1),                    //选择膨胀或腐蚀操作，1 腐蚀、0 膨胀
    .din_val            (din_val),
    .din                (din),
    
    //同步信号
    .morph_row_wr_en    (morph_wr_en1),
    .cam_href_r         (cam_href_r1),          //行同步信号
    .cam_vsync_r        (cam_vsync_r1),         //场同步信号  
    
    .dout_CRS8b         (),           //腐蚀数据     
    .dout_EPS8b         (),                     //膨胀数据
    .dout_CRS1b         (dout_CRS1b1),          //腐蚀数据     
    .dout_EPS1b         ()                      //膨胀数据    
    
);

//一维列形态学模块    
morph_line u1_morph_line(
    .module_clk         (module_clk),           //数据入栈驱动时钟
    .module_clk2        (module_clk2),          //模块工作时钟
    .module_rst_n       (module_rst_n),
    
    .cam_href           (cam_href_r1),          //摄像头行同步信号，用于复位计数器
    .cam_vsync          (cam_vsync_r1),            //场同步信号       
    .EPS_CRS            (1'd1),                    //选择膨胀或腐蚀操作，1 腐蚀、0 膨胀
    .din_val            (morph_wr_en1),
    .din                (dout_CRS1b1),
    
    .cam_href_r         (cam_href_r2),          //行同步信号
    .cam_vsync_r        (cam_vsync_r2),         //场同步信号  
    
    .morph_line_wr_en   (morph_wr_en),
    .dout_CRS8b         (dout_CRS8b),                     //腐蚀数据    
    .dout_EPS8b         (),                     //膨胀数据
    .dout_CRS1b         (),          //腐蚀数据     
    .dout_EPS1b         ()                      //膨胀数据    
);

//************************************//

    

    endmodule