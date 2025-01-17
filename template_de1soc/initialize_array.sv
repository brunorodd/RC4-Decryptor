module initialize_array(clk, address, write_enable, data, done_init, reset_task, start);
input logic clk;
input logic start;
input logic reset_task;
output logic [7:0] data;
output logic [7:0] address; //i
output logic write_enable;
output logic done_init;
// this will be an 8-bit number that is used to implement the algorithm for task 1
logic [7:0] i = 8'b0;

// for (i = 0; i < 255; i++)
	// s[i] = i

	// Task 1
	
logic increase, write_s, done;
logic [2:0] state;

assign address = i; 
assign data = address;
assign done_init = done;

parameter [2:0] idle = 3'b000;
parameter [2:0] write = 3'b001;
parameter [2:0] increment = 3'b010;
parameter [2:0] end_init = 3'b100;

assign increase = state[1];
assign write_enable = state[0];
assign done = state[2];

// writes to the memory sequentially 
always_ff @ (posedge clk)
begin
	case (state)
		idle:	 
			if (start)
				state <= write;
			else
				state <= idle;
		
		write: state <= increment;
		
		increment: if (i < 255)
							state <= write;
					  else 
							state <= end_init;
						
		end_init: state <= idle; //acts as another idle but with done = 1 and keeps returning back to it

		default: state <= idle;
							
	endcase
end

// i++
always_ff @ (posedge clk)
begin
	if (increase)
		i = i + 1;
	if (reset_task)
		i = 0;
end

endmodule
