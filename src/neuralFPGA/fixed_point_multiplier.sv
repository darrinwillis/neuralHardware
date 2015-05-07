
module fixed_point_multiplier (
	input bit[31:0] dataa, datab,
	output bit[31:0] result);

	bit[15:0] intA, fracA, intB, fracB;
	bit[31:0] iAiB, iAfB, fAiB, fAfB;

	assign intA = dataa[31:16]; 
	assign fracA = {dataa[31], dataa[15:1]};
	assign intB = datab[31:16];
	assign fracB = {datab[31], datab[15:1]};

	multiplier_16 int1int2(
		.dataa(intA),
		.datab(intB),
		.result(iAiB));

	multiplier_16 int1frac2(
		.dataa(intA),
		.datab(fracB),
		.result(iAfB));

	multiplier_16 frac1int2(
		.dataa(fracA),
		.datab(intB),
		.result(fAiB));

	multiplier_16 frac1frac2(
		.dataa(fracA),
		.datab(fracB),
		.result(fAfB));

	// Shift over all bits appropriately and add

	assign result = {iAiB, 16'd0} + 
					iAfB +
					fAiB +
					{fAfB[31] ? 16'hffff : 16'h0000, fAfB[30:15]};

endmodule: fixed_point_multiplier