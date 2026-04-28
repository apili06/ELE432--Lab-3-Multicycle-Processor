module datapath (
    input  logic        clk, reset,
    // Control signals from controller
    input  logic [1:0]  alusrca,    // 00=PC, 01=OldPC, 10=rs1(A)
    input  logic [1:0]  alusrcb,    // 00=rs2(B), 01=ImmExt, 10=4
    input  logic [1:0]  resultsrc,  // 00=ALUOut, 01=Data, 10=ALUResult
    input  logic        adrsrc,     // 0=PC, 1=ALUOut
    input  logic [2:0]  alucontrol,
    input  logic [1:0]  immsrc,
    input  logic        irwrite,    // Instruction register write enable
    input  logic        pcwrite,    // PC write enable
    input  logic        regwrite,   // Register file write enable
    // Memory interface
    input  logic [31:0] readdata,   // Data read from memory
    output logic [31:0] adr,        // Address to memory (PC or ALUOut)
    output logic [31:0] writedata,  // Data to write to memory (rs2)
    // Status
    output logic        zero,
    // Debug / testbench outputs
    output logic [31:0] instr,
    output logic [31:0] pc
);
    // Internal signals
    logic [31:0] next_pc;
    logic [31:0] old_pc;
    logic [31:0] immext;
    logic [31:0] src_a, src_b;
    logic [31:0] alu_result;
    logic [31:0] alu_out;    // Registered ALU result
    logic [31:0] data;       // Registered memory read data
    logic [31:0] rd1, rd2;   // Register file outputs
    logic [31:0] a;          // Registered rs1
    logic [31:0] result;     // Write-back mux output

    // PC register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) pc <= 32'h0;
        else if (pcwrite) pc <= result;
    end

    // Instruction register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            instr  <= 32'h0;
            old_pc <= 32'h0;
        end else if (irwrite) begin
            instr  <= readdata;
            old_pc <= pc;
        end
    end

    // Register file
    regfile rf (
        .clk     (clk),
        .we3     (regwrite),
        .a1      (instr[19:15]),  // rs1
        .a2      (instr[24:20]),  // rs2
        .a3      (instr[11:7]),   // rd
        .wd3     (result),
        .rd1     (rd1),
        .rd2     (rd2)
    );

    always_ff @(posedge clk) begin
        a         <= rd1;
        writedata <= rd2;
    end

   
    extend ext (
        .instr  (instr[31:7]),
        .immsrc (immsrc),
        .immext (immext)
    );

    // ALU source muxes
    always_comb begin
        case (alusrca)
            2'b00:   src_a = pc;
            2'b01:   src_a = old_pc;
            2'b10:   src_a = a;
            default: src_a = 32'hx;
        endcase
    end

    always_comb begin
        case (alusrcb)
            2'b00:   src_b = writedata;
            2'b01:   src_b = immext;
            2'b10:   src_b = 32'd4;
            default: src_b = 32'hx;
        endcase
    end

    // ALU
    alu alu (
        .a          (src_a),
        .b          (src_b),
        .alucontrol (alucontrol),
        .result     (alu_result),
        .zero       (zero)
    );


    // ALUOut register
    always_ff @(posedge clk) begin
        alu_out <= alu_result;
    end

    // Data register
    always_ff @(posedge clk) begin
        data <= readdata;
    end

    always_comb begin
        case (resultsrc)
            2'b00:   result = alu_out;
            2'b01:   result = data;
            2'b10:   result = alu_result;
            default: result = 32'hx;
        endcase
    end
	 
    assign adr = adrsrc ? alu_out : pc;

endmodule

// Register File
module regfile (
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  a1, a2, a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1, rd2
);
    logic [31:0] rf [31:0];

    always_ff @(posedge clk) begin
        if (we3) rf[a3] <= wd3;
    end

    assign rd1 = (a1 != 5'b0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 5'b0) ? rf[a2] : 32'b0;
endmodule


// Immediate Extender
// immsrc: 00=I-type, 01=S-type, 10=B-type, 11=J-type
module extend (
    input  logic [31:7] instr,
    input  logic [1:0]  immsrc,
    output logic [31:0] immext
);
    always_comb begin
        case (immsrc)
            2'b00: immext = {{20{instr[31]}}, instr[31:20]};                          // I-type
            2'b01: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};             // S-type
            2'b10: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};  // B-type
            2'b11: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type
            default: immext = 32'hx;
        endcase
    end
endmodule

// ALU
// alucontrol: 000=AND, 001=OR, 010=ADD, 110=SUB, 111=SLT
module alu (
    input  logic [31:0] a, b,
    input  logic [2:0]  alucontrol,
    output logic [31:0] result,
    output logic        zero
);
    logic [31:0] condinvb;
    logic [31:0] sum;

    assign condinvb = alucontrol[2] ? ~b : b;
    assign sum      = a + condinvb + alucontrol[2]; 

    always_comb begin
        case (alucontrol)
            3'b000:  result = a & b;
            3'b001:  result = a | b;
            3'b010:  result = sum;
            3'b110:  result = sum;
            3'b111:  result = {31'b0, sum[31]};  
            default: result = 32'hx;
        endcase
    end

    assign zero = (result == 32'b0);
endmodule