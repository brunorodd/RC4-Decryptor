module FSM_controller(clk, q, wren, data, address, secret_key);
input logic clk;
input logic [23:0] secret_key;
output logic wren; // write_enable
output logic [7:0] data, address;

logic [1:0] keylength = 1'd3;
logic done_initialization = 1'b0;

// j = 0
logic [7:0] j = 8'b0;
logic [7:0] i;

logic [7:0] state;
logic increase_counter;

parameter [7:0] idle = 8'b0000_0000;
parameter [7:0] set_j_equals = 8'b0000_0001;
parameter [7:0] swap_si_sj = 
parameter [7:0] increment = 8'b0001_00

assign increase_counter = state[4];

// Modular approach for Task 1 (initializing the array)
initialize_array THE_ONE_TRUE_ARRAY_INITIALIZER( .clk(clk),
																 .address(i),
																 .write_enable(wren),
																 .data(data)
																 .remain(done_initialization));
/*								 *\
 ---Beginning of Task 2---
\*								 */


// j =0
// for i = 0 to 255 {
//	j = j + s[i] + secret_key[i % keylength]
// swap s[i] and s[j]  }


// for i = 0 to 255
always @ (posedge clk)
begin
	if (increase_counter)
		i = i + 1;
end
		

always @ (posedge clk)
begin
	if (done_initialization) 
		begin 
			case (state)
				idle: 
				
				
			endcase
		end
end
		
endmodule
