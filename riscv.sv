module riscv (
    input  logic        clk, reset,
    input  logic [31:0] readdata,    
    output logic [31:0] adr,         
    output logic [31:0] writedata,   
    output logic        memwrite,    
    output logic [31:0] pc,
    output logic [31:0] instr
);

    // Controller
    logic [1:0] immsrc;
    logic [1:0] alusrca, alusrcb;
    logic [1:0] resultsrc;
    logic       adrsrc;
    logic [2:0] alucontrol;
    logic       irwrite, pcwrite;
    logic       regwrite;

    logic zero;
    // Fields that go from Instruction to Controller
    logic [6:0] op;
    logic [2:0] funct3;
    logic       funct7b5;

    assign op      = instr[6:0];
    assign funct3  = instr[14:12];
    assign funct7b5 = instr[30];

    // Controller
    controller ctrl (
        .clk        (clk),
        .reset      (reset),
        .op         (op),
        .funct3     (funct3),
        .funct7b5   (funct7b5),
        .zero       (zero),
        .immsrc     (immsrc),
        .alusrca    (alusrca),
        .alusrcb    (alusrcb),
        .resultsrc  (resultsrc),
        .adrsrc     (adrsrc),
        .alucontrol (alucontrol),
        .irwrite    (irwrite),
        .pcwrite    (pcwrite),
        .regwrite   (regwrite),
        .memwrite   (memwrite)
    );

    // Datapath
    datapath dp (
        .clk        (clk),
        .reset      (reset),
        .alusrca    (alusrca),
        .alusrcb    (alusrcb),
        .resultsrc  (resultsrc),
        .adrsrc     (adrsrc),
        .alucontrol (alucontrol),
        .immsrc     (immsrc),
        .irwrite    (irwrite),
        .pcwrite    (pcwrite),
        .regwrite   (regwrite),
        .readdata   (readdata),
        .adr        (adr),
        .writedata  (writedata),
        .zero       (zero),
        .instr      (instr),
        .pc         (pc)
    );

endmodule