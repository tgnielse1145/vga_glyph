module movement 
#(parameter DATA_WIDTH=16, ADDR_WIDTH=16)
(
	input clk, reset,
	input [(DATA_WIDTH-1):0] data_in,
	output reg [(ADDR_WIDTH-1):0] addr,
	output reg [(DATA_WIDTH-1):0] data_out,
	output reg we
);


localparam COUNT = 12500000;	// 500 sec
//localparam COUNT = 10;
localparam STATE_ITER = 3;
wire timer;

// clk divider
pulse clk_div (
	clk, reset,
	STATE_ITER, COUNT,
	timer
);


localparam FETCH_X = 3'd0, SAVE_X = 3'd1;
localparam FETCH_Y = 3'd2, SAVE_Y = 3'd3;
localparam FETCH_M = 3'd4, SAVE_M = 3'd5, SAVE_M_STANDING = 3'd6;
localparam OBJ_X = 3'd8, SAVEOBJ_X = 3'd9;
localparam OBJ_Y = 3'd10, SAVEOBJ_Y = 3'd11;
localparam OBJ_M = 3'd12, SAVEOBJ_M = 3'd13, SAVEOBJ_M_STANDING = 3'd14;
localparam IDLE = 3'd7;
reg [2:0] PS, NS;


localparam MARIO_X_END = 500;
localparam OBJ_X_END = 500;

localparam MARIO_STANDING   = 0;
localparam MARIO_WALK_START = 1;
localparam MARIO_WALK_MID   = 2;
localparam MARIO_WALK_END   = 3;
localparam OBJ_STANDING   = 100;
localparam OBJ_WALK_START = 101;
localparam OBJ_WALK_MID   = 102;
localparam OBJ_WALK_END   = 103;
reg inc_in, inc_out;

// dff for mario walking animation (increment or decrement walk pattern)
always @(posedge clk)
	inc_out <= inc_in;


always @(posedge clk) begin
	if (reset) 		 PS <= FETCH_X;
	else if (timer) PS <= NS;
	else		  PS <= PS;
end


always @(PS, data_in, inc_out) begin

	addr = 'hx;
	data_out = 'hx;
	we = 1'b0;
	inc_in = 1'bx;
	
	case (PS)
		
		FETCH_X: begin
			addr = 'h1000;
			NS = SAVE_X;
		end
		
		SAVE_X: begin
			addr = 'h1000;
			data_out = data_in + 3'd4;
			we = 1'b1;
			if (data_in < MARIO_X_END)
				NS = FETCH_M;	// I don't want to change Y
			else
				NS = SAVE_M_STANDING;
		end
		
//		FETCH_Y: begin
//			addr = 'h1001;
//			NS = SAVE_Y;
//		end
//		
//		SAVE_Y: begin
//			addr = 'h1001;
//			data_out = data_in + 1'b1;
//			we = 1'b1;
//		end
		
		FETCH_M: begin
			addr = 'h1002;
			NS = SAVE_M;
		end
		
		SAVE_M: begin
			addr = 'h1002;
			we = 1'b1;
			case (data_in)
				MARIO_STANDING: begin
					data_out = MARIO_WALK_START;
					inc_in = 1'b1;
				end
				
				MARIO_WALK_START: begin
					data_out = MARIO_WALK_MID;
					inc_in = 1'b1;
				end
				
				MARIO_WALK_MID: begin
				$display("here i am in MARIO_WALK_MID and here is inc_out %d \n ", inc_out);
				$display("here i am in MARIO_WALK_MID and here is inc_in %d \n ", inc_in);
					if (inc_out) data_out = MARIO_WALK_START;
					else		data_out = MARIO_WALK_END;
					inc_in = inc_out;
					$display("here i am in MARIO_WALK_MID2 and here is inc_out %d \n ", inc_out);
				$display("here i am in MARIO_WALK_MID2 and here is inc_in %d \n ", inc_in);
				end
				
				MARIO_WALK_END: begin
					data_out = MARIO_WALK_MID;
					inc_in = 1'b0;
				end
				
				default: begin
					data_out = 'hx;
					inc_in = 1'bx;
				end
			endcase
			NS = FETCH_X;
		end
		
		SAVE_M_STANDING: begin
			addr = 'h1002;
			//data_out = MARIO_STANDING;
			data_out = OBJ_X;
			$display("here i am in SAVE_M_STANDING and are we gonna go to OBJ_X \n");
			we = 1'b1;
			NS = OBJ_X;
		end
		OBJ_X: begin
			addr = 'h1003;
			NS = SAVEOBJ_X;
		end
		
		SAVEOBJ_X: begin
			addr = 'h1003;
			data_out = data_in + 3'd4;
			we = 1'b1;
			if (data_in < OBJ_X_END)
				NS = OBJ_M;	// I don't want to change Y
			else
				NS = SAVEOBJ_M_STANDING;
		end
		OBJ_M: begin
			addr = 'h1005;
			NS = SAVEOBJ_M;
		end
		
		SAVEOBJ_M: begin
			addr = 'h1005;
			we = 1'b1;
			case (data_in)
				OBJ_STANDING: begin
					data_out = OBJ_WALK_START;
					inc_in = 1'b1;
				end
				
				OBJ_WALK_START: begin
					data_out = OBJ_WALK_MID;
					inc_in = 1'b1;
				end
				
				OBJ_WALK_MID: begin
					if (inc_out) data_out = OBJ_WALK_START;
					else		data_out = OBJ_WALK_END;
					inc_in = inc_out;
				end
				
				OBJ_WALK_END: begin
					data_out = OBJ_WALK_MID;
					inc_in = 1'b0;
				end
				
				default: begin
					data_out = 'hx;
					inc_in = 1'bx;
				end
			endcase
			NS = OBJ_X;
		end
		IDLE: begin
			NS = IDLE;
		end
	
	endcase 
	
end

endmodule
