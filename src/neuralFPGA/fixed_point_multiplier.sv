
module fixed_point_multiplier (
	input bit[31:0] dataa, datab,
	output bit[31:0] result);

	bit[63:0] rawResult;

	multiplier_32 int1int2(
		.dataa(dataa),
		.datab(datab),
		.result(rawResult));


	// Shift over all bits appropriately and add

	assign result = rawResult[47:16];

endmodule: fixed_point_multiplier