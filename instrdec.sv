module instrdec (input logic [6:0] op,
	 output logic [1:0] ImmSrc);
	 always_comb
	 case(op)
	 7'b0110011: ImmSrc = 2'bxx; // R-type
	 7'b0010011: ImmSrc = 2'b00; // I-type ALU
	 7'b0000011: ImmSrc = 2'b00; // lw
	 7'b0100011: ImmSrc = 2'b01; // sw
	 7'b1100011: ImmSrc = 2'b10; // beq
	 7'b1101111: ImmSrc = 2'b11; // jal
	 default: ImmSrc = 2'bxx; // ???
	 
	 endcase
endmodule