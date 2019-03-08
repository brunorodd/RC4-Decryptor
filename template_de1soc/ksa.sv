module ksa(CLOCK_50, KEY, SW, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
input logic CLOCK_50;
input logic [3:0] KEY;
input logic [9:0] SW;

output logic [9:0] LEDR;
output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
 
logic clk, reset_n;
logic [3:0] nIn;
logic [6:0] ssOut;

// signals for task 1
logic [7:0] address, data, q;
logic [31:0] i;
logic write_enable;

assign clk = CLOCK_50;
assign reset_n = KEY[3];

SevenSegmentDisplayDecoder YOOOOO(.ssOut(HEX0), .nIn(nIn));

/*								 *\				
 ---Beginning of Task 1/2---
\*								 */

logic [13:0] zeros = 14'b0;

FSM_controller YOOO2(.clk(clk),
							.q(q),
							.wren(wren),
							.data(data),
							.address(address),
							/* concatenating bits of zeros up until the 14th bit */
							.secret_key({zeros, SW[9:0]}));	
		
// initializing the S memory and filling in with numbers
s_memory S(.clock(clk), // s[i] array
			  .address(address),
			  .data(data),
			  .wren(write_enable),
			  .q(q));
/*								 *\				
	----End of Task 1----- 
\*								 */
								  
endmodule 