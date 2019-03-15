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
logic increase_sk;

assign clk = CLOCK_50;
assign reset_n = KEY[3];




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



SevenSegmentDisplayDecoder hex0(.ssOut(HEX0), .nIn(super_secret_key[3:0]));
SevenSegmentDisplayDecoder hex1(.ssOut(HEX1), .nIn(super_secret_key[7:4]));
SevenSegmentDisplayDecoder hex2(.ssOut(HEX2), .nIn(super_secret_key[11:8]));
SevenSegmentDisplayDecoder hex3(.ssOut(HEX3), .nIn(super_secret_key[15:12]));
SevenSegmentDisplayDecoder hex4(.ssOut(HEX4), .nIn(super_secret_key[19:16]));
SevenSegmentDisplayDecoder hex5(.ssOut(HEX5), .nIn(super_secret_key[23:20]));


/*								 *\				
 ---Beginning of Task 1/2---
\*								 */

logic [15:0] state;
logic [23:0] super_secret_key = 24'h0;
logic increase_key;
logic reset_values;
logic task1_start;
logic task2a_start;
logic task2b3_start;


parameter [15:0] idle 									= 16'b00_00_00_000_000_0000;
parameter [15:0] start_task1 							= 16'b00_00_00_001_000_0001;
parameter [15:0] wait_task1								= 16'b00_00_00_000_000_0010;
parameter [15:0] start_task2a 							= 16'b01_01_01_010_000_0010;
parameter [15:0] wait_task2a							= 16'b01_01_01_000_000_0011;
parameter [15:0] start_task2b_3							= 16'b11_11_11_100_000_0011;
parameter [15:0] wait_task2b_3							= 16'b11_11_11_000_000_0100;
parameter [15:0] reset_loop_counters_states 			= 16'b00_00_00_000_001_0100;
parameter [15:0] end_decrypt							= 16'b00_00_00_000_000_0101;
parameter [15:0] increment_sk							= 16'b00_00_00_000_010_0110;
parameter [15:0] no_secret								= 16'b00_00_00_000_000_0111;

assign reset_values   = state[4];
assign increase_key   = state[5];

assign task1_start  	 = state[7];
assign task2a_start 	 = state[8];
assign task2b3_start  = state[9];

assign address_access = {state[11],state[10]};
assign data_access	 = {state[13],state[12]};
assign write_access	 = {state[15],state[14]};

/*assign address_access = {done_task2a, done_task1}; // THIS NEEDS CHANGING*/
// have to communicate with all three FSMS (master FSM)
always_ff @ (posedge clk)
	begin
	case(state)
		idle: if (super_secret_key >= 24'h3FFFFF)
					state <= no_secret;
				else
					state <= start_task1;

		// initializing loop 1 
		start_task1: 	state <= wait_task1;

		wait_task1:		if (done_task1)
							state <= start_task2a;
						else
							state <= wait_task1;
								
		// initializes loop 2
		start_task2a: 		state <= wait_task2a;

		wait_task2a: 	if (done_task2a) 
								state <= start_task2b_3;
							else 
								state <= wait_task2a;
								
		// initializes loop 3
		start_task2b_3: state <= wait_task2b_3;
								
		wait_task2b_3:   	if (done_task2b)
								state <= end_decrypt;
								
							 else if (increase_sk)
								state <= reset_loop_counters_states;
								
							 else 
								state <= wait_task2b_3;
							 
reset_loop_counters_states: state <= increment_sk;

			increment_sk: state <= idle;

								
			end_decrypt:  state <= end_decrypt;
			
			no_secret: state <= no_secret;

			 default: 	state <= idle;	
			 endcase
end
	
always_ff @ (posedge clk)
begin
	if (increase_key)
		super_secret_key = super_secret_key+1'b1;
	else 
		super_secret_key <= super_secret_key;
end
initialize_array THE_ONE_TRUE_ARRAY_INITIALIZER(.clk(clk),
																.address(initializing_address),
																.write_enable(initializing_wren),
																.data(initializing_data),
																.done_init(done_task1),
																.reset_task(reset_values),
																.start(task1_start));
FSM_controller THE_ONE_TRUE_FSM(.clk(clk),
										  .q(q),
										  .wren(code_wren),
										  .data(code_data),
										  .address(code_address),
											/* concatenating bits of zeros up until the 14th bit */
										  .secret_key(super_secret_key),
										  .s_filled(done_task1),
										  .done_task2a(done_task2a),
										  .reset_task(reset_values),
										  .start(task2a_start));	
										  
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
											 .q_s(q),
											 .increase_key(increase_sk),
											 .reset_task(reset_values),
											 .start(task2b3_start));		
											 
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
		     .q(q));*/

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
		   .q(q_m));
			*/
			
/*								 *\				
	----End of Task 1----- 
\*								 */
								  
endmodule 