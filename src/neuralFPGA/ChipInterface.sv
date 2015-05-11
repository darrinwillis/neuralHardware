`timescale 1 ns / 1 ns
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

    /*SimpleTest st(
    	.clk(CLOCK_50),
    	.sw(SW),
    	.key(KEY),
    	.hexDisplays({HEX7, HEX6 ,HEX5, HEX4, HEX3, HEX2, HEX1, HEX0}));*/

	/*MemTest mt(
    	.clk(CLOCK_50),
    	.sw(SW),
    	.key(KEY),
    	.hexDisplays({HEX7, HEX6 ,HEX5, HEX4, HEX3, HEX2, HEX1, HEX0}));*/

	NeuralHookup nh(
    	.clk(CLOCK_50),
    	.sw(SW),
    	.key(KEY),
    	.hexDisplays({HEX7, HEX6 ,HEX5, HEX4, HEX3, HEX2, HEX1, HEX0}));

endmodule: ChipInterface

module TopTest;
    bit clk;
    bit[17:0] sw;
    bit[3:0] key;
    bit[15:0] finalVal;
    bit[7:0][6:0] hexDisplays;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
        end

    initial begin
        key <= 4'b1110;
        @(posedge clk);
        key <= 4'b1111;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        key[1] <= 0;
        @(posedge clk);
        key[1] <= 1;
        wait(hexDisplays[0] != 7'b1000000);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        sw <= 18'd2;
        key[2] <= 0;
        @(posedge clk);
        key[2] <= 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        
        $finish;
        end


	NeuralHookup nh(
    	.clk(clk),
    	.sw(sw),
    	.key(key),
    	.hexDisplays(hexDisplays));

endmodule: TopTest

module NeuralHookup
    (input  bit   clk,
     input  bit[17:0] sw,
     input  bit[3:0] key,
     output bit [7:0][6:0] hexDisplays);

	bit[31:0] mem_data, out;
	bit[10:0] address;
	neuralProcessor np(
		.clk(clk),
		.rst(~key[0]),
		.train(~key[1]),
		.test(~key[2]),
		.test_sel(sw[7:0]),
		.mem_data(mem_data),
		.address(address),
		.test_output(out));

    romBlock rb(
    	.address(address),
    	.clock(clk),
    	.q(mem_data));

    //Generate the seven segment display
    genvar k;
    generate
        for (k = 0; k < 8; k=k+1) begin : SEV_SEG
            SevenSegmentDigit ssd(
                //.bch((k > 3) ? resultB[31-4*(k-4) : 31-4*(k-3)] : resultA[31-4*k : 31-4*(k+1)]),
                .bch(out[4*(k+1)-1 : 4*k]),
                .segment(hexDisplays[k]),
                .blank(1'b0));
            end
    endgenerate

endmodule: NeuralHookup

module MemTest
    (input  bit   clk,
     input  bit[17:0] sw,
     input  bit[3:0] key,
     output bit [7:0][6:0] hexDisplays);

	bit[31:0] memOut;

    romBlock rb(
    	.address(sw[10:0]),
    	.clock(clk),
    	.q(memOut));

    //Generate the seven segment display
    genvar k;
    generate
        for (k = 0; k < 8; k=k+1) begin : SEV_SEG
            SevenSegmentDigit ssd(
                //.bch((k > 3) ? resultB[31-4*(k-4) : 31-4*(k-3)] : resultA[31-4*k : 31-4*(k+1)]),
                .bch(memOut[4*(k+1)-1 : 4*k]),
                .segment(hexDisplays[k]),
                .blank(1'b0));
            end
    endgenerate

endmodule: MemTest

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