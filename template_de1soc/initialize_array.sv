module initialize_array(clk, address, write_enable, data);
input logic clk;
output logic [7:0] data;
output logic [7:0] address;
output logic write_enable;
// this will be an 8-bit number that is used to implement the algorithm for task 1
logic [7:0] i = 8'b0;

// for (i = 0; i < 255; i++)
	// s[i] = i

	// Task 1
	
logic increase, write_s, done;
logic [2:0] state;

logic remain = 1'b0;

assign address = i; 
assign data = address;

parameter [2:0] idle = 3'b000;
parameter [2:0] write = 3'b001;
parameter [2:0] increment = 3'b010;
parameter [2:0] end_init = 3'b100;

assign increase = state[1];
assign write_enable = state[0];
assign done = state[2];


always_ff @ (posedge done)
begin
	remain = 1'b1;
end	

always_ff @ (posedge clk)
begin
	case (state)
		idle: if (remain)
					state <= idle;
				else
					state <= write;
		
		write: state <= increment;
		
		increment: if (i < 256)
							state <= idle;
					  else 
							state <= end_init;
						
		end_init: state <= idle;

		default: state <= idle;
							
	endcase
end

always_ff @ (posedge clk)
begin
	if (increase)
		i = i + 1;
end

endmodule
