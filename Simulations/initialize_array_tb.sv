module initialize_array_tb();
logic [7:0] s [0:255];
logic clk;

initialize_array dut(.s_array(s), .clk(clk));

always begin
clk = 1'b0;
#1;
clk = 1'b1;
#1;
end
initial begin
#2000;

$display(s[1]);
$display(s[244]);
$display(s[15]);
$stop;
end

endmodule
