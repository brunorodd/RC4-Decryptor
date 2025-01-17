/*
i = 0, j=0
for k = 0 to message_length-1 { // message_length is 32 in our implementation
	i = i+1
	j = j+s[i]
		swap values of s[i] and s[j]
		f = s[ (s[i]+s[j]) ]
	decrypted_output[k] = f xor encrypted_input[k] // 8 bit wide XOR function
}
*/

module FSM_controller2(clk, address_d, data_d, wren_d, address_m, q_m, address_s, data_s, wren_s, q_s, done_task2a, done_task2b, reset_task, increase_key, start);
input logic clk;
input logic start;
output logic [7:0] address_d, data_d, address_m;
input logic [7:0] q_m;
output logic wren_d; // outputs to decrypt are correct
output logic wren_s;
output logic [7:0] address_s, data_s;
input logic [7:0] q_s;
input logic  done_task2a;
output logic done_task2b;
input logic reset_task;
output logic increase_key;

logic [7:0] i = 8'b0;
logic [7:0] j = 8'b0; 
logic [7:0] k = 8'b0;

logic [7:0] si, sj;
logic [5:0] message_length = 6'b100000; // 32
logic [7:0] si_sj;
logic [7:0] encrypted_input;
logic [7:0]  f; 
logic [7:0] s_si_sj;

logic increment_count_i;
logic increment_count_k;
logic store_si_enable;
logic store_sj_enable;
logic set_j;
logic [1:0] choose_address;
logic choose_data_bit;
logic done;
logic set_f;
logic store_si_sj_enable;
logic si_sj_enable; 

logic [20:0] state;

parameter [20:0] idle                   = 21'b00000000_00_000_000_00000;
// i = i+1
parameter [20:0] increment_i            = 21'b00000000_00_000_001_00001; // increment_count_i = 1, (i = i + 1);

// retrieve s[i]
parameter [20:0] get_si                 = 21'b00000000_00_000_000_00010; // 
parameter [20:0] wait_si                = 21'b00000000_00_000_000_00011; // choose_address = 00 (i)
parameter [20:0] store_si               = 21'b00000000_00_001_000_00100; // store_si_enable   = 1, (si = q_s);

// j = j + s[i]
parameter [20:0] store_j                = 21'b00000000_00_100_000_00101; // set_j = 1, j = j + si

//good 

// retrieve s[j]
parameter [20:0] get_sj                 = 21'b00000000_01_000_000_00110; // choose_address    = {0, 1}, address_s = j;
parameter [20:0] wait_sj                = 21'b00000000_01_000_000_00111; // choose_address    = {0, 1}, address_s = j;
parameter [20:0] store_sj               = 21'b00000000_01_010_000_01000; // // choose_address    = {0, 1}, address_s = j, store_sj_enable = 1, (sj = q_s)

// swap (s[i], s[j]) // writing s[i] to address j
parameter [20:0] write_to_mem_si	       = 21'b00010000_01_000_000_01001; // wren_s = 1, address_s = j, choose_data_bit = 0, data = si; 
parameter [20:0] wait_for_mem_si	       = 21'b00000000_01_000_000_01010; // wait 

parameter [20:0] wait_one_cycle	     	 = 21'b00000001_00_000_000_01011; // wait one clock cycle
// swap (s[i], s[j]) // 
parameter [20:0] write_to_mem_sj        = 21'b00010001_00_000_000_01100; // wren_s = 1, address_s = i, choose_data_bit = 1, data = sj;
parameter [20:0] wait_for_mem_sj        = 21'b00000001_00_000_000_01101; // wait

// retrieve s[i] + s[j]
parameter [20:0] set_si_sj              = 21'b00100000_00_000_000_11111; // Will store si + sj into a temporary register called logic si_sj

// retrieve s[s[i]+s[j]]
parameter [20:0] get_s_si_sj            = 21'b00000000_10_000_000_01110; // choose_address = {1, 0} (address = si_sj) [si + sj]; 
parameter [20:0] wait_s_si_sj           = 21'b00000000_10_000_000_01111; // wait 
parameter [20:0] store_s_si_sj          = 21'b00001000_10_000_000_10000; // store_si_sj_enable = 1,  s_si_sj = q_s, q = s[s[i] + s[j]]

// f = s[s[i] + s[j]]
parameter [20:0] store_f                = 21'b00000100_00_000_000_10001; // f = s[s[i] + s[j]]

// retrieve encrypted_input[k]
parameter [20:0] get_encrypted_input    = 21'b00000000_00_000_000_10010; // address_m = k, address_d = k, encrypted_input = q_m
parameter [20:0] wait_encrypted_input   = 21'b00000000_00_000_000_10011; // address_m is k which means we'll get encrypted_input at the kth address (ie. encrypted_input[k])
parameter [20:0] store_encrypted_input  = 21'b00000000_00_000_000_10100; 

// decrypted_output[k] = f XOR encrypted_input[k]
parameter [20:0] write_decrypted_output = 21'b01000000_00_000_000_10101; // address_d = k, data_d = f XOR encrypted_input[k], wren_d = 1
parameter [20:0] wait_decrypted_output  = 21'b00000000_00_000_000_10110;
parameter [20:0] increment_k            = 21'b00000000_00_000_100_10111;
parameter [20:0] check_key 				 = 21'b00000000_00_000_000_11010;
parameter [20:0] increment_key			 = 21'b10000000_00_000_000_11000;
parameter [20:0] decrypt_done           = 21'b00000010_00_000_000_10111;

assign increment_count_i = state[5];
assign increment_count_k = state[7];
assign store_si_enable   = state[8];
assign store_sj_enable   = state[9];
assign set_j             = state[10];
assign choose_address    = {state[12], state[11]};
assign choose_data_bit   = state[13];
assign done              = state[14];
assign set_f             = state[15];
assign store_si_sj_enable= state[16];

assign wren_s            = state[17];

assign si_sj_enable      = state[18];
assign wren_d            = state[19];

assign increase_key		 = state[20];

assign data_s    = choose_data_bit    ? sj: si;
assign data_d = f ^ encrypted_input; /*decrypted output[k] = f XOR encrypted_input[k]*/ 

assign address_m = k; 
assign address_d = k; 

always_comb begin
   case(choose_address)
	 2'b00: address_s = i;
	 2'b01: address_s = j;
	 2'b10: address_s = si_sj;
	 default: address_s = 0;
	 endcase 
end

	
assign encrypted_input   = q_m;

assign done_task2b       = done;

always_ff @(posedge clk)

begin
		case(state)
		
        idle: if (start)
						state <= increment_i;
				  else 
						state <= idle;
 
 increment_i: state <= get_si;
 
      get_si: state <= wait_si;
		
	  wait_si: state <= store_si;
	
	store_si: state <= store_j;

	store_j: state <= get_sj;

	get_sj: state <= wait_sj;

	wait_sj: state <= store_sj;

	store_sj: state <= write_to_mem_si;

	write_to_mem_si: state <= wait_for_mem_si;

	wait_for_mem_si: state <= wait_one_cycle;

	wait_one_cycle: state <= write_to_mem_sj;

	write_to_mem_sj: state <= wait_for_mem_sj;

	wait_for_mem_sj: state <= set_si_sj;

	set_si_sj      : state <= get_s_si_sj;

	get_s_si_sj    : state <= wait_s_si_sj;

	wait_s_si_sj   : state <= store_s_si_sj;

	store_s_si_sj		  : state <= store_f;

	store_f        	  : state <= get_encrypted_input;

	get_encrypted_input : state <= wait_encrypted_input;

	wait_encrypted_input: state <= store_encrypted_input;

	store_encrypted_input: state <= check_key;

	check_key: 	if (data_d == 8'd32 || (data_d >= 8'd97 && data_d <= 8'd122)) 
					begin
						state <= write_decrypted_output;
					end				
				else 
						state <= increment_key;
						
	write_decrypted_output: state <= wait_decrypted_output;

	wait_decrypted_output: state <= increment_k;
	
	increment_key: state <= idle; // was state <= increase_key which would make it increase keys infinitely

	increment_k: 				if (k < (31)) 
										state <= increment_i;
									else if (k == 31) 
										state <= decrypt_done;

		decrypt_done: state <= decrypt_done;		
				 
			default: state <= idle;

			endcase
end
// i = i + 1
always_ff @(posedge clk) begin 
	if (increment_count_i)
		i = i + 1;
	if (reset_task)
		i = 0;
end

// k++
always_ff @ (posedge clk) begin
	if (increment_count_k)
		k = k + 1;
	else if (reset_task)
		k = 0;
end

// store s[i]
always_ff @(posedge clk) begin
	if (store_si_enable) 
		si <= q_s;
	if (reset_task)
		si <= 0;
end

// store s[j]
always_ff @(posedge clk) begin
	if (store_sj_enable) 
		sj <= q_s;
	if (reset_task)
		sj <= 0;
end

// store j = j + s[i]
always_ff @(posedge clk) begin
if (set_j) 
	j <= j + si;
if (reset_task)
	j <= 0;
end

// f - s[s[i]+s[j]]
always_ff @(posedge clk) begin
if (set_f) 
	f <= s_si_sj;

end

always_ff @(posedge clk) begin
if (si_sj_enable) 
	si_sj <= si + sj;

end

always_ff @(posedge clk) begin
if (store_si_sj_enable) 
	s_si_sj <= q_s;

end


endmodule
