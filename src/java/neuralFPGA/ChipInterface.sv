module ChipInterface
    (input  logic   CLOCK_50,
     input  logic[9:0] SW,
     input  logic[2:0] KEY,
     output logic[6:0] HEX7, HEX6 ,HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

    SimpleTest st(
    	.clk(CLOCK_50),
    	.sw(SW),
    	.key(KEY),
    	.hexDisplays({HEX7, HEX6 ,HEX5, HEX4, HEX3, HEX2, HEX1, HEX0}));

endmodule: ChipInterface

module SimpleTest
    (input  bit   clk,
     input  bit[9:0] sw,
     input  bit[2:0] key,
     output bit [7:0][6:0] hexDisplays);

	bit [7:0][3:0] values;
	assign values = {4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8};

    //Generate the seven segment display
    genvar k;
    generate
        for (k = 0; k < 8; k=k+1) begin : SEV_SEG
            SevenSegmentDigit ssd(
                .bch(values[k]),
                .segment(hexDisplays[k]),
                .blank(1'b0));
            end
    endgenerate

endmodule: SimpleTest