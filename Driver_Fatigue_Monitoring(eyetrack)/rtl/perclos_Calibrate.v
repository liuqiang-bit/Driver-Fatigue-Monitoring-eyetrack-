module perclos_calibrate (
    input   module_clk,
    input   module_rst_n,
    input  [10:0]lcd_pixel_xpos,          
    input  [10:0]lcd_pixel_ypos,          
    
    input  [10:0] eye1_high,
    input  [10:0] eye2_high,
    input  [10:0] eye1_wide,
    input  [10:0] eye2_wide,
    output        beep
    );

wire beep1      ;
wire beep2      ;

assign beep = (beep1 & beep2) ? 0 : 1   ;

perclos_calculate u1_perclos_calculate(
    .module_clk         (module_clk),
    .module_rst_n       (module_rst_n),
    .lcd_pixel_xpos     (lcd_pixel_xpos),          
    .lcd_pixel_ypos     (lcd_pixel_ypos),          
    
    .eye_high           (eye1_high),
    .eye_wide           (eye1_wide), 
    .beep               (beep1)
    );    

perclos_calculate u2_perclos_calculate(
    .module_clk         (module_clk),
    .module_rst_n       (module_rst_n),
    .lcd_pixel_xpos     (lcd_pixel_xpos),          
    .lcd_pixel_ypos     (lcd_pixel_ypos),          
    
    .eye_high           (eye2_high),
    .eye_wide           (eye2_wide), 
    .beep               (beep2)
    );   
   


endmodule
