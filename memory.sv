module memory (
    input  logic        clk,
    input  logic        we, // MemWrite
    input  logic [31:0] a,  // Adress
    input  logic [31:0] wd, // WriteData
    output logic [31:0] rd  // ReadData 
);
    logic [31:0] RAM [63:0];// 64word = 256byte

    initial $readmemh("riscvtest.txt", RAM);

    assign rd = RAM[a[31:2]];
	 
    always_ff @(posedge clk) begin
        if (we) RAM[a[31:2]] <= wd;
    end

endmodule