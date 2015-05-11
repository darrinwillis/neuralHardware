module ChipInterface
    (input  logic   CLOCK_50,
     input  logic[17:0] SW,
     input  logic[3:0] KEY,
     output logic[17:0] LEDR,
     output logic[8:0] LEDG,
     output logic[6:0] HEX7, HEX6 ,HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

    assign LEDR = SW;
    assign LEDG = {2'd0, ~KEY[3],
    			   1'b0, ~KEY[2],
    			   1'b0, ~KEY[1],
    			   1'b0, ~KEY[0]};

    SimpleTest st(
    	.clk(CLOCK_50),
    	.sw(SW),
    	.key(KEY),
    	.hexDisplays({HEX7, HEX6 ,HEX5, HEX4, HEX3, HEX2, HEX1, HEX0}));

endmodule: ChipInterface

module SimpleTest
    (input  bit   clk,
     input  bit[17:0] sw,
     input  bit[3:0] key,
     output bit [7:0][6:0] hexDisplays);

	bit [31:0] mult, result;

	assign mult = {8'd0, sw[15:0], 8'd0};

	sigmoid sg(.data(mult), .result(result));

    //Generate the seven segment display
    genvar k;
    generate
        for (k = 0; k < 8; k=k+1) begin : SEV_SEG
            SevenSegmentDigit ssd(
                //.bch((k > 3) ? resultB[31-4*(k-4) : 31-4*(k-3)] : resultA[31-4*k : 31-4*(k+1)]),
                .bch(result[4*(k+1)-1 : 4*k]),
                .segment(hexDisplays[k]),
                .blank(1'b0));
            end
    endgenerate

endmodule: SimpleTest