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
logic [7:0] address, data, q, code_data;
logic [7:0] initializing_data;
logic [31:0] i;
logic write_enable;
logic address_access;
logic data_access;
logic done_initialization;

logic [7:0] initializing_address, code_address;
logic initializing_wren, code_wren;

assign clk = CLOCK_50;
assign reset_n = KEY[3];

assign address_access = 1'b1 & done_initialization;
assign data_access	= 1'b1 & done_initialization;
assign write_access  = 1'b1 & done_initialization;

assign address = address_access ? code_address : initializing_address;
assign data = data_access ? code_data : initializing_data;
assign write_enable = write_access ? code_wren : initializing_wren;


SevenSegmentDisplayDecoder YOOOOO(.ssOut(HEX0), .nIn(nIn));

/*								 *\				
 ---Beginning of Task 1/2---
\*								 */
logic [9:0] key1 =10'b1001001001; 

logic [13:0] zeros = 14'b0;
							
initialize_array THE_ONE_TRUE_ARRAY_INITIALIZER(.clk(clk),
																.address(initializing_address),
																.write_enable(initializing_wren),
																.data(initializing_data),
																.done_init(done_initialization)
																);
FSM_controller THE_ONE_TRUE_FSM(.clk(clk),
										  .q(q),
										  .wren(code_wren),
										  .data(code_data),
										  .address(code_address),
											/* concatenating bits of zeros up until the 14th bit */
										  .secret_key({zeros, SW[9:0]}),
										  .s_filled(done_initialization),
										  .done_task2a(done_task2a));	

logic [7:0] address_d, address_m, data_d, q_m, q_d;
logic wren_d;
logic done_task2a, done_task2b;		
									  
FSM_controller2 THE_ONE_TRUE_FSM2(.clk(clk),
											 .q_m(q_m),
											 .address_d(address_d),
											 .address_m(address_m),
											 .wren(wren_d),
											 .data(data_d),
											 .done_task2a(done_task2a),
											 .done_task2b(done_task2b));																
// initializing the S, D (Decrypted), E (Encrypted) memory and filling in with numbers
s_memory S(.clock(clk), // s[i] array
			  .address(address), // feed address and clk to get q back
			  .data(data),
			  .wren(write_enable),
			  .q(q));
			  
d_memory D(.address(address_d),
			  .clock(clk),
			  .data(data_d),
			  .wren(wren_d),
			  .q(q_d));

e_memory E(.address(address_m),
			  .clock(clk),
			  .q(q_m));

/*								 *\				
	----End of Task 1----- 
\*								 */
								  
endmodule 