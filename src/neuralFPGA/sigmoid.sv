module sigmoid (
	input bit[31:0] data,
	output bit[31:0] result);

	bit[31:0] abs_data, mult_val, add_val, mult_result, lin_result;

	assign abs_data = data[31] ? (~data + 1) : data;

	assign mult_val = (abs_data < 32'h0001_0000) ? 32'h0000_4000 : // 0.25
					  (abs_data < 32'h0002_6000) ? 32'h0000_2000 : // 0.125
					  (abs_data < 32'h0005_0000) ? 32'h0000_0800 : // 0.03125
					  32'h0000_0000; // 0.0
	assign add_val =  (abs_data < 32'h0001_0000) ? 32'h0000_8000 : // 0.5
					  (abs_data < 32'h0002_6000) ? 32'h0000_A000 : // 0.625
					  (abs_data < 32'h0005_0000) ? 32'h0000_0800 : // 0.84375
					  32'h0001_0000; // 1.0

	fixed_point_multiplier  fpm(
		.dataa(data),
		.datab(mult_val),
		.result(mult_result));

	// Shift over all bits appropriately and add

	assign lin_result = mult_result + add_val;

	assign result = (data < 32'd0) ? 1 - lin_result : lin_result;

endmodule: sigmoid