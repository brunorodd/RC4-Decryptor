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
module FSM_controller2(clk, q, address_d, data_d, wren_d, address_m, q_m);

endmodule
