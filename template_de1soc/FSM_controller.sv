// this is the main fsm that will be used to execute the second block of code
module FSM_controller(clk, q, wren, data, address, secret_key, s_filled, done_task2a, reset_task, start);
input logic clk;
input logic start;
input logic [7:0] q;
input logic [23:0] secret_key;
input logic s_filled;
output logic wren; // write_enable
output logic [7:0] data, address;
output logic done_task2a; 
input logic reset_task;
logic done;

logic [23:0] secret_key_stored;

logic [1:0] keylength = 2'd3;
logic [7:0] si, sj; // stores the array values of s[i] and s[j] 

// j = 0
logic [7:0] j = 1'b0; // will be used to store j when the j = j +s[i] + secret_key[i % keylength] is used 
logic [7:0] i = 1'b0;
logic [7:0] i_mod_key;


logic [14:0] state; // first state for the FSM // to resolve multiple drivers
logic increase_i_counter, set_j, choose_data, swap, store_si_enable, store_sj_enable;


// Modular approach for Task 1 (initializing the array)

// states
parameter [14:0] idle    			 = 15'b00_0000_0000_00000;
parameter [14:0] get_si 			 = 15'b00_0000_0000_00001; // choose_reg has i set first as the address and will get the q bus on the second output
parameter [14:0] wait_si			 = 15'b00_0000_0010_00010;
parameter [14:0] store_si		    = 15'b00_0000_0010_00011; // this sets the enable for si to high so we can store the output of the q bus into si in this module on the next clock
parameter [14:0] store_j 			 = 15'b00_0000_1000_00100; // this makes it so that we can store j as j = j +s[i] + secret_key[i_mod_key] on the next clock

parameter [14:0] get_sj				 = 15'b00_0010_0000_00101; // choose_reg has j set now as the current address to retrieve the output q at address j
parameter [14:0] wait_sj			 = 15'b00_0010_0000_00110;
parameter [14:0] store_sj			 = 15'b00_0010_0100_00111; // this sets the enable for sj to high to store the current output of the q bus into sj on the next clock cycle
// important states to write to memory // 
parameter [14:0] write_to_mem_si	 = 15'b01_0010_0000_01000; // wren = 1, choose_data = 0 (data = si), choose_address = 1 (address = j)
parameter [14:0] wait_for_mem_si	 = 15'b00_0010_0000_01010;
parameter [14:0] wait_one_cycle	 = 15'b00_0100_0000_00110;
parameter [14:0] write_to_mem_sj  = 15'b01_0100_0000_01011; // wren = 1, choose_data = 1 (data = sj), choose_address = 0 (address = 1)
parameter [14:0] wait_for_mem_sj  = 15'b00_0100_0000_01100;
parameter [14:0] increment_i 		 = 15'b00_0001_0000_01101;
parameter [14:0] end_task2a 		 = 15'b00_1000_0000_01110;

// assigning state outputs
assign swap 							 = state[5];
assign store_si_enable				 = state[6];
assign store_sj_enable				 = state[7];
assign set_j 							 = state[8];
assign increase_i_counter 			 = state[9];
assign choose_address  				 = state[10]; // chooses which address (either i or j)
assign choose_data 					 = state[11];
assign done 							 = state[12];
assign wren 							 = state[13];

assign i_mod_key   = i % keylength; 

assign address     = (choose_address)? j : i;
assign data 		 = (choose_data) ? sj : si;
assign done_task2a = done;

/*-------------------------------------------------------------------------------*\
-------------------------------Beginning of Task 2---------------------------------
\*-------------------------------------------------------------------------------*/


// j =0
// for i = 0 to 255 {
//	j = j + s[i] + secret_key[i % keylength]
// swap s[i] and s[j]  }
// resets i to 0 when s array is done being filled so it can be used in the next loop

//==========================================================================================\\
// NOTE: THIS FSM WILL NOT RUN UNTIL THE S_MEMORY IS DONE FILLING IN HENCE THE IF STATEMENT \\
//==========================================================================================\\

always_ff @ (posedge clk) 
begin
// this state machine will not run until the S memory is filled 

			case (state)
		 	      idle:	if (start)
									state <= get_si;
							else 
									state <= idle;
				  
				 get_si:/* address <= i;
						 wren <=1'b0;
						 */
						
						state <= wait_si;
						
			  wait_si: state <= store_si;
					
		     store_si: /* si <= q; // this state will wait around two clock cycles to get si from the memory
			 			*/
						state <= store_j; 
				
				store_j: /* j <= j + si + secret_key[i_mod_key];
				*/
						state <= get_sj; 
							
				 get_sj: /* address <= j;
							wren = 1'b0;
							*/
						state <= wait_sj; // after this state, j will be loaded with j = j +s[i]+secret_key[i mod keylength] and sent to the S RAM
						
				wait_sj: state <= store_sj;
				
			  store_sj: /* sj <= q;
							*/
						state <= write_to_mem_si; // after this state, sj will be loaded from the q output of the S RAM
			
	// these states do the 'swapping'		
	 write_to_mem_si: /* wren = 1'b1;
						 address <= j;
						 data <= si;
						*/
						state <= wait_for_mem_si; 
	 
	 wait_for_mem_si: /*
							*/
						state <= wait_one_cycle;
	 
	 wait_one_cycle: state <= write_to_mem_sj;
	 
	 write_to_mem_sj: state <= wait_for_mem_sj;
	 
	 wait_for_mem_sj: /* wren = 1'b1;
						 address <= i;
						 data <= sj;
						*/
						state <= increment_i;
	 
		  increment_i: if (i < 255)
								state <= get_si;
							else
								state <= end_task2a;
								
			end_task2a: state <= idle;
			
				default: state <= idle;
				
			endcase
end

// initializes i to zero for this loop (only executes once)

// for i = 0 to 255
always_ff @ (posedge clk)
begin
	if (increase_i_counter)
		i = i + 1;
   if (reset_task)
		i = 0;
end

// j = j + s[i] + secret_key[i % keylength]
always_ff @ (posedge clk)
begin 
	if (set_j)
		j <= j + si + secret_key_stored;	
	if (reset_task)
		j <= 0; 
	
end

// setting si
always_ff @ (posedge clk)
begin 
	if (store_si_enable)
		si <= q;
	if (reset_task)
		si <= 0;
end

// setting sj
always_ff @ (posedge clk)
begin 
	if (store_sj_enable)
		sj <= q;
	if (reset_task)
		sj <= 0;
end	

always_comb 
begin 
	case(i_mod_key)
		2'b00: secret_key_stored = secret_key[23:16];
		2'b01: secret_key_stored = secret_key[15:8];
		2'b10: secret_key_stored = secret_key[7:0];
		default: secret_key_stored = 0;
	endcase
end	
endmodule
