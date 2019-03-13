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

logic [1:0] address_access;
logic [1:0] data_access;
logic [1:0] write_access;

logic done_task1;

logic [7:0] initializing_address, code_address;
logic initializing_wren, code_wren;


logic [7:0] address_d, address_m, data_d, q_m, q_d;
logic wren_d;
logic done_task2a, done_task2b;		
logic [7:0] data_s, address_s;
logic wren_s;					

assign clk = CLOCK_50;
assign reset_n = KEY[3];

assign address_access = {done_task2a, done_task1}; 
assign data_access	=  {done_task2a, done_task1}; 
assign write_access  =  {done_task2a, done_task1}; 

always_comb begin
  case(data_access)
	2'b00: data = initializing_data;
	2'b01: data = code_data;
	2'b11: data = data_s;
	default: data = 0;
	endcase
end

always_comb begin
  case(address_access)
	2'b00: address = initializing_address;
	2'b01: address = code_address;
	2'b11: address = address_s;
	default: address = 0;
	endcase
end

always_comb begin
  case(write_access)
	2'b00: write_enable = initializing_wren;
	2'b01: write_enable = code_wren;
	2'b11: write_enable = wren_s;
	default: write_enable = 0;
	endcase
end



//SevenSegmentDisplayDecoder YOOOOO(.ssOut(HEX0), .nIn(nIn));

/*								 *\				
 ---Beginning of Task 1/2---
\*								 */

logic [13:0] zeros = 14'b0;
logic [9:0] key1 = 10'b1001001001;
							
initialize_array THE_ONE_TRUE_ARRAY_INITIALIZER(.clk(clk),
																.address(initializing_address),
																.write_enable(initializing_wren),
																.data(initializing_data),
																.done_init(done_task1)
																);
FSM_controller THE_ONE_TRUE_FSM(.clk(clk),
										  .q(q),
										  .wren(code_wren),
										  .data(code_data),
										  .address(code_address),
											/* concatenating bits of zeros up until the 14th bit */
										  .secret_key({zeros, SW[9:0]}),
										  .s_filled(done_task1),
										  .done_task2a(done_task2a));	
										  
FSM_controller2 THE_ONE_TRUE_FSM2(.clk(clk),
											 .q_m(q_m),
											 .address_d(address_d),
											 .address_m(address_m),
											 .wren_d(wren_d),
											 .data_d(data_d),
											 .done_task2a(done_task2a),
											 .done_task2b(done_task2b),
											 .address_s(address_s),
											 .data_s(data_s),
											 .wren_s(wren_s),
											 .q_s(q));		
											 
// initializing the S, D (Decrypted), E (Encrypted) memory and filling in with numbers
s_memory S(.clock(clk), // s[i] array
			  .address(address), // feed address and clk to get q back
			  .data(data),
			  .wren(write_enable),
			  .q(q));
			  
/*sdp_memory S(.clock(clk),
		     .data(data),
		     .wraddress(address),
		     .wren(write_enable),
		     .q(q));
*/
d_memory D(.address(address_d),
			  .clock(clk),
			  .data(data_d),
			  .wren(wren_d),
			  .q(q_d));

/*o_memory D(.clock(clk),
		     .data(data_d),
		     .address(address_d),
		     .wren(wren_d),
		     .q(q_d));*/
e_memory E(.address(address_m),
			  .clock(clk),
			  .q(q_m));

/*
e_memory E(.clock(clk),
		   .address(address_m),
		   .q(q_m));*/
			
/*								 *\				
	----End of Task 1----- 
\*								 */
								  
endmodule 