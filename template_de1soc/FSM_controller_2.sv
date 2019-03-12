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
module FSM_controller2(clk, address_d, data_d, wren_d, address_m, q_m, address_s, data_s, wren_s, q_s, done_task2a,
											 done_task2b);
input logic  clk;
output logic [7:0] address_d, data_d, address_m;
input logic [7:0] q_m;
output logic wren_d;
input logic wren_s;
output logic [7:0] address_s, data_s;
input logic [7:0] q_s;
input logic  done_task2a;
output logic done_task2b;

logic [7:0] i = 0;
logic [7:0] j = 0; 
logic [7:0] k = 0;

logic [19:0] state;

parameter [19:0] idle                   = 20'b00000000_0000_000_00000;
parameter [19:0] increment_i            = 20'b00000000_0000_001_00001;
parameter [19:0] get_si                 = 20'b00000000_0000_000_00010;
parameter [19:0] wait_si                = 20'b00000000_0000_000_00011;
parameter [19:0] store_si               = 20'b00000000_0001_000_00100;
parameter [19:0] store_j                = 20'b00000000_0100_000_00101;       //Change values of bits
parameter [19:0] get_sj                 = 20'b00000000_1000_000_00110;
parameter [19:0] wait_sj                = 20'b00000000_1000_000_00111;
parameter [19:0] store_sj               = 20'b00000000_1100_000_01000; 
parameter [19:0] write_to_mem_si	       = 20'b00100000_1000_000_01001; 
parameter [19:0] wait_for_mem_si	       = 20'b00000000_1000_000_01010; 
parameter [19:0] wait_one_cycle	     	 = 20'b00000000_0000_000_01011;
parameter [19:0] write_to_mem_sj        = 20'b00100010_0000_000_01100;  
parameter [19:0] wait_for_mem_sj        = 20'b00000000_0100_000_01101; 
parameter [19:0] set_si_sj              = 20'b01000000_0000_000_11111; // Will store si + sj into a temporary register called logic si_sj
parameter [19:0] get_s_si_sj            = 20'b00000001_0000_000_01110; 
parameter [19:0] wait_s_si_sj           = 20'b00000001_0000_000_01111; //
parameter [19:0] store_s_si_sj          = 20'b00010000_0000_000_10000;
parameter [19:0] store_f                = 20'b00001000_0000_000_10001;
parameter [19:0] get_encrypted_input    = 20'b00000000_0000_000_10010;
parameter [19:0] wait_encrypted_input   = 20'b00000000_0000_000_10011;
parameter [19:0] store_encrypted_input  = 20'b00000000_0000_000_10100;
parameter [19:0] write_decrypted_output = 20'b10000000_0000_000_10101;
parameter [19:0] wait_decrypted_output  = 20'b00000000_0000_000_10110;
parameter [19:0] increment_k            = 20'b00000000_0000_100_10111;
parameter [19:0] end_task2b             = 20'b00000000_0000_000_10111;
logic increment_count_i;
logic increment_count_k;
logic store_si_enable;
logic store_sj_enable;
logic set_j;
logic choose_address;
logic choose_data_bit;
logic done;
logic set_f;
logic store_si_sj_enable;
logic [7:0] si, sj;
logic [5:0] message_length = 6'b1000000;
logic si_sj_enable; 
logic si_sj;
logic encrypted_input;
logic [7:0]  f; 
logic [7:0] s_si_sj;

assign data_s    = choose_data_bit    ? sj: si;
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

assign increment_count_i = state[5];
assign increment_count_j = state[6];
assign increment_count_k = state[7];
assign store_si_enable   = state[8];
assign store_sj_enable   = state[9];
assign set_j             = state[10];
assign choose_address    = {state[12], state[11]};
assign choose_data_bit   = state[13];
assign done              = state[14];
assign set_f             = state[15];
assign store_si_sj_enable= state[16];
assign wren              = state[17];
assign si_sj_enable      = state[18];
assign wren_d            = state[19];
assign encrypted_input   = q_m;
assign data_d            = encrypted_input ^ f;
assign done_task2b       = done;
always_ff @(posedge clk )begin
   if(done_task2a) begin
	case(state)
        idle: state <= increment_i;
 
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
store_s_si_sj  : state <= store_f;
store_f        : state <= get_encrypted_input;
get_encrypted_input : state <= wait_encrypted_input;
wait_encrypted_input: state <= store_encrypted_input;
store_encrypted_input: state <= write_decrypted_output;
write_decrypted_output: state <= wait_decrypted_output;
wait_decrypted_output: state <= increment_k;
increment_k          : if (k < (message_length - 1)) state <= idle;
                       else  state <= end_task2b;
end_task2b           : state <= end_task2b;
default              : state <= idle;
endcase
 end
end

always_ff @(posedge clk) begin
if (store_si_enable) si <= q_s;

end

always_ff @(posedge clk) begin
if (store_sj_enable) sj <= q_s;

end

always_ff @(posedge clk) begin
if (set_j) j <= j + si;

end

always_ff @(posedge clk) begin
if (set_f) f <= s_si_sj;

end

always_ff @(posedge clk) begin
if (si_sj_enable) si_sj <= si + sj;

end

always_ff @(posedge clk) begin
if (store_si_sj_enable) s_si_sj <= q_s;

end

endmodule
