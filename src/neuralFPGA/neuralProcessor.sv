module neuralProcessor (
	input bit clk, rst,
	input bit train, test,
	input bit[7:0] test_sel,
	input bit[31:0] mem_data,
	output bit[31:0] address,
	output bit[31:0] test_output);

	// Control Signals for FSM
	bit 	last_train;
	bit  	load_num_train,
			load_num_test,
			load_mem, 
			load_sum,
			load_hout,
			load_output,
			load_oerror,
			load_herror,
			load_new_weights,
			inc_address,
			rst_address,
			store_test_out;
	bit[2:0] input_sel;

	// Meta-data
	bit[7:0] numTest, numTrain;

	// Weights
	bit[31:0] learn_rate;
	bit[31:0] iw; // initial weight
	assign iw = 32'h0000_3800; // 1/8 + 1/16 + 1/32 ~ 0.22 ~ 0.2
	bit[4:0][31:0] input_values;
	bit[3:0][3:0][31:0] input_to_hidden_weights;
	bit[3:0][31:0] hidden_to_output_weights;
	bit[3:0][3:0][31:0] hidden_products;
	bit[3:0][31:0] hidden_sums;
	bit[3:0][31:0] hidden_outputs;
	bit[3:0][31:0] output_products;
	bit[31:0] final_output;
	bit[31:0] output_error, output_diff, output_inversion, output_err_temp;
	bit[3:0][31:0] hidden_error, hidden_inversion, hidden_err_temp1, hidden_err_temp2;
	bit[3:0][3:0][31:0] hidden_correction, hidden_correc_temp;
	bit[3:0][31:0] out_correction;
	bit[31:0] out_error_temp;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            numTest <= 0;
            numTrain <= 0;
            learn_rate <= 32'h0000_4000; // 0.25
            input_to_hidden_weights[3][3] <= iw;
            input_to_hidden_weights[3][2] <= iw;
            input_to_hidden_weights[3][1] <= iw;
            input_to_hidden_weights[3][0] <= iw;

            input_to_hidden_weights[2][3] <= iw;
            input_to_hidden_weights[2][2] <= iw;
            input_to_hidden_weights[2][1] <= iw;
            input_to_hidden_weights[2][0] <= iw;

            input_to_hidden_weights[1][3] <= iw;
            input_to_hidden_weights[1][2] <= iw;
            input_to_hidden_weights[1][1] <= iw;
            input_to_hidden_weights[1][0] <= iw;

            input_to_hidden_weights[0][3] <= iw;
            input_to_hidden_weights[0][2] <= iw;
            input_to_hidden_weights[0][1] <= iw;
            input_to_hidden_weights[0][0] <= iw;

            hidden_to_output_weights[3] <= iw;
            hidden_to_output_weights[2] <= iw;
            hidden_to_output_weights[1] <= iw;
            hidden_to_output_weights[0] <= iw;

            end
        else begin
        	if (load_mem) begin
        		input_values[input_sel] = mem_data;
        		end
            if (load_num_train) begin
                numTrain <= mem_data;
                end
            if (load_num_test) begin
            	numTest <= mem_data;
            	end
            if (load_new_weights) begin
            	for (int i=0; i < 4; i++) begin
            		for (int l=0; l < 4; l++) begin
            			input_to_hidden_weights[i][j] =
            				input_to_hidden_weights[i][j] + hidden_correction[i][j];
            			end
            		hidden_to_output_weights[i] = 
            			hidden_to_output_weights[i] + out_correction[i];
            		end
            	end
            end
        end

	neuralFSM NFSM(.*);

	// Create all of the hidden outputs and sums
	genvar k, j;
	generate
		for (k=0; k<4; k++) begin: HID_MULTS_OUTER
			for (j=0; j < 4; j++) begin: HID_MULTS_INNER
				fixed_point_multiplier HIDMULT(
					.dataa(input_to_hidden_weights[k][j]),
					.datab(input_values[k]),
					.result(hidden_products[k][j]));
			end

			// Sum contributions from all inputs
			adder4_32 summer(
				.data0x(hidden_products[0][k]),
				.data1x(hidden_products[1][k]),
				.data2x(hidden_products[2][k]),
				.data3x(hidden_products[3][k]),
				.result({2'b00, hidden_sums[k]}));

			// Perform activation function on sum
			sigmoid sigm(
				.data(hidden_sums[k]),
				.result(hidden_outputs[k]));

			fixed_point_multiplier OUTMULT(
				.dataa(hidden_outputs[k]),
				.datab(hidden_to_output_weights[k]),
				.result(output_products[k]));
		end
	endgenerate

	adder4_32 sumOut(
		.data0x(output_products[0]),
		.data1x(output_products[1]),
		.data2x(output_products[2]),
		.data3x(output_products[3]),
		.result({2'b00, final_output}));

	// Generate the error function
	assign output_diff = input_values[4] - final_output;
	assign output_inversion = 32'h0001_0000 - final_output;
	fixed_point_multiplier OERR_MULT(
		.dataa(output_diff),
		.datab(output_inversion),
		.result(output_err_temp));
	fixed_point_multiplier OERR_FINAL_MULT(
		.dataa(output_err_temp),
		.datab(final_output),
		.result(output_error));
	
	// Generate the hidden error functions
	assign hidden_inversion[3] = 1 - hidden_outputs[3];
	assign hidden_inversion[2] = 1 - hidden_outputs[2];
	assign hidden_inversion[1] = 1 - hidden_outputs[1];
	assign hidden_inversion[0] = 1 - hidden_outputs[0];

	generate
		for (k=0; k<4; k++) begin: HID_ERRORS
			fixed_point_multiplier HERR_TEMP1(
				.dataa(hidden_outputs[k]),
				.datab(hidden_inversion[k]),
				.result(hidden_err_temp1[k]));

			fixed_point_multiplier HERR_TEMP2(
				.dataa(output_error),
				.datab(hidden_to_output_weights[k]),
				.result(hidden_err_temp2[k]));

			fixed_point_multiplier HERR_FINAL(
				.dataa(hidden_err_temp2[k]),
				.datab(hidden_err_temp1[k]),
				.result(hidden_error[k]));
		end
	endgenerate


	// Create the new values for the weights
	generate
		for (k=0; k<4; k++) begin: HID_NEW_OUTER

			fixed_point_multiplier HID_CORRECT_TEMP1(
				.dataa(learn_rate),
				.datab(hidden_error[j]),
				.result(hidden_correc_temp));

			for (j=0; j < 4; j++) begin: HID_NEW_INNER
				fixed_point_multiplier HID_CORRECT_TEMP1(
					.dataa(hidden_correc_temp),
					.datab(input_values[j]),
					.result(hidden_correction));
			end
		end
	endgenerate

	fixed_point_multiplier out_correc(
		.dataa(learn_rate),
		.datab(output_error),
		.result(out_error_temp));
	// Create new values for output weights
	generate
		for (k=0; k<4; k++) begin: OUT_NEW
			fixed_point_multiplier HID_CORRECT_TEMP1(
				.dataa(out_error_temp),
				.datab(hidden_outputs[k]),
				.result(out_correction[k]));
		end
	endgenerate

endmodule: neuralProcessor

module neuralFSM (
	input  bit  clk, rst, train, test, last_train,
	output bit  load_num_train,
				load_num_test,
				load_mem, 
				load_sum,
				load_hout,
				load_output,
				load_oerror,
				load_herror,
				load_new_weights,
				inc_address,
				rst_address,
				store_test_out,
	output bit[2:0] input_sel
);

	logic[7:0] numIterations;
	bit dec_iterations;
	bit training_mode, load_mode;
	enum logic[3:0] {INIT1, INIT2, WAIT, LOADED_TRAIN, LOADED_OUT,
					 O_ERR_CALCED, H_ERR_CALCED, DATUM_DONE, 
					 LOADED_TEST, LOADED_TEST_OUT} cs, ns;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            cs <= INIT1;
            numIterations <= 8'd200;
            input_sel <= 2'd0;
            training_mode <= 'b0;
            end
        else begin
            cs <= ns;
            if (dec_iterations) begin
            	numIterations <= numIterations - 1;
            	end
            if (load_mode) begin
            	training_mode <= train;
            	end
        	end
        end

    always_comb begin
    	load_num_train = 'b0;
    	load_num_test = 'b0;
        load_mem = 'b0;
        load_sum = 'b0;
        load_hout = 'b0;
        load_output = 'b0;
        load_oerror = 'b0;
        load_herror = 'b0;
        load_new_weights = 'b0;
        dec_iterations = 'b0;
        store_test_out = 'b0;
        case (cs) 
            INIT1: begin
                ns = INIT2;
                load_num_train = 'b1;
                end
            INIT2: begin
                ns = WAIT;
                load_num_test = 'b1;
                end
            WAIT:  begin
                ns = train ? LOADED_TRAIN : (test ? LOADED_TEST : WAIT);
                load_mem = train;
                end
            LOADED_TRAIN: begin
            	ns = LOADED_OUT;
            	load_sum = 'b1;
            	load_hout = 'b1;
            	load_output = 'b01;
            	end
           	LOADED_OUT: begin
           		ns = O_ERR_CALCED;
           		load_oerror = 'b1;
	           	end
	        O_ERR_CALCED: begin
	        	ns = H_ERR_CALCED;
	        	load_herror = 'b1;
	        	end
	        H_ERR_CALCED: begin
	        	ns = DATUM_DONE;
	        	load_new_weights = 'b1;
	        	inc_address = 'b1;
	        	end
	        DATUM_DONE: begin
	        	ns = last_train && numIterations == 0 ? WAIT : LOADED_TRAIN;
	        	rst_address = last_train && numIterations != 0;
	        	load_mem = ~(last_train && numIterations == 0);
	        	dec_iterations = 'b1;
	        	end
	        // Now just states dealing with testing, not training
	        LOADED_TEST: begin
	        	ns = LOADED_TEST_OUT;
	        	store_test_out = 'b1;
	        	end
	       	LOADED_TEST_OUT: begin
	       		ns = WAIT;
	       		end
        endcase
        end

endmodule