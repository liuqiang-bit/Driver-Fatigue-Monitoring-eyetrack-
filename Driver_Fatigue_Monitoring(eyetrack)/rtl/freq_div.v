module freq_div(
    input       freq_in,
    
    output  reg    freq_out
    );
    
    initial begin
        freq_out <= 0;
    end
    always @(posedge freq_in ) begin
        freq_out <= !freq_out;
end 
    endmodule