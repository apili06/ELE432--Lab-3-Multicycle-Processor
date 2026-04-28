module controller(input logic clk,
	input logic reset,
	input logic [6:0] op,
	input logic [2:0] funct3,
	input logic funct7b5,
	input logic zero,
	output logic [1:0] immsrc,
	output logic [1:0] alusrca, alusrcb,
	output logic [1:0] resultsrc,
	output logic adrsrc,
	output logic [2:0] alucontrol,
	output logic irwrite, pcwrite,
	output logic regwrite, memwrite);
				
typedef enum logic [3:0] {
   Fetch,
   Decode,
   MemAdr,
   MemRead,
   MemWB,
   MemWrite,
   ExecuteR,
   ALUWB,
   ExecuteI,
   JAL,
   BEQ 
 } state_t;
    	 
	state_t state, next_state;
	logic [1:0] aluop;
	logic pcupdate;
	logic branch;

  always_ff @(posedge clk or posedge reset) begin
      if (reset) 
          state <= Fetch;
      else       
          state <= next_state;
  end

  always_comb begin
      adrsrc   = 1'b0;
      irwrite  = 1'b0;
      alusrca  = 2'b00;
      alusrcb  = 2'b00;
      aluop    = 2'b00;
      resultsrc= 2'b00;
      pcupdate = 1'b0;
      branch   = 1'b0;
      regwrite = 1'b0;
      memwrite = 1'b0;
		
      case(state)
          Fetch: begin
              adrsrc    = 1'b0;
              irwrite   = 1'b1;
              alusrca   = 2'b00;
              alusrcb   = 2'b10;
              aluop     = 2'b00;
              resultsrc = 2'b10;
              pcupdate  = 1'b1;
              
              next_state = Decode; 
          end
          
          Decode: begin
              
              alusrca   = 2'b01;
              alusrcb   = 2'b01;
              aluop     = 2'b00;
             
              if (op == 7'b0000011 || op == 7'b0100011) 
                  next_state = MemAdr;
              else if (op == 7'b0110011)
                  next_state = ExecuteR;
              else if (op == 7'b0010011)
						next_state = ExecuteI;
				  else if (op == 7'b1101111)
						next_state = JAL;
				  else
						next_state = BEQ;		
          end
			 
			 MemAdr: begin
				  
				  alusrca   = 2'b10;
              alusrcb   = 2'b01;
              aluop     = 2'b00;
				 
				 if (op == 7'b0000011)
					  next_state = MemRead;
				 else 
					  next_state = MemWrite;
			 end
			 
			 MemRead: begin
				 resultsrc = 2'b00;
				 adrsrc    = 1;
				 next_state = MemWB;
			 end
			 
			 MemWrite: begin
				 resultsrc = 2'b00;
				 adrsrc    = 1;
				 memwrite = 1'b1;
				 next_state = Fetch;
			 end
			 
			 ExecuteR: begin
				 alusrca   = 2'b10;
             alusrcb   = 2'b00;
             aluop     = 2'b10;
				 next_state = ALUWB;
			 end
			 
			 ExecuteI: begin
				 alusrca   = 2'b10;
             alusrcb   = 2'b01;
             aluop     = 2'b10;
				 next_state = ALUWB;
			 end
			 
			 JAL: begin
				 alusrca   = 2'b01;
             alusrcb   = 2'b10;
             aluop     = 2'b00;
				 resultsrc = 2'b00;
				 pcupdate = 1'b1;
				 next_state = ALUWB;
			 end
			 
			 ALUWB: begin
				 resultsrc = 2'b00;
				 regwrite = 1'b1;
				 next_state = Fetch;
			 end
			 
			 BEQ: begin
				 alusrca   = 2'b10;
             alusrcb   = 2'b00;
             aluop     = 2'b01;
				 resultsrc = 2'b00;
				 branch = 1'b1;
				 next_state = Fetch;
			 end
			 
			 MemWB: begin
				 resultsrc = 2'b01;
				 regwrite = 1'b1;
				 next_state = Fetch;
			 end
			 
          default: next_state = Fetch;
      endcase
  end
  assign pcwrite = pcupdate | (branch & zero);
  
  instrdec id (
      .op(op),
      .ImmSrc(immsrc)
  );
  
  aludec ad(
		.opb5(op[5]),
      .funct3(funct3),
      .funct7b5(funct7b5),
      .ALUOp(aluop),
      .ALUControl(alucontrol)
  );
endmodule  