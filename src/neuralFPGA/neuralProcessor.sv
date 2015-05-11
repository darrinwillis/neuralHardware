module neuralProcessor (
	input bit clk, rst,
	input bit train, test,
	input bit[7:0] test_sel,
	input bit[31:0] mem_data,
	output bit[10:0] address,
	output bit[31:0] test_output);

	// Control Signals for FSM
	bit 	last_train;
	bit  	load_num_train,
			load_num_test,
			load_mem, 
			load_output,
			load_oerror,
			load_herror,
			load_new_weights,
			inc_address,
			rst_address,
			store_test_out,
			ready_to_test;
	bit[2:0] input_sel;

	// Meta-data
	bit[7:0] numTest, numTrain;
	bit[31:0] learn_rate;
	bit[31:0] iw; // initial weight
	assign iw = 32'h0000_3800; // 1/8 + 1/16 + 1/32 ~ 0.22 ~ 0.2

	// Parameters
	bit[3:0][3:0][31:0] hidden_products;
	bit[3:0][31:0] hidden_sums;
	bit[3:0][31:0] hidden_outputs;
	bit[3:0][31:0] output_products;

	// Stored values (not intermediate calculations)
	bit[4:0][31:0] input_values;
	bit[3:0][3:0][31:0] stored_hidden_weights;
	bit[3:0][31:0] stored_output_weights;
	bit[3:0][31:0] stored_hidden_outputs;
	bit[31:0] stored_final_output;

	// Update parameters info
	bit[31:0] final_output;
	bit[31:0] output_error, output_diff, output_inversion, output_err_temp;
	bit[3:0][31:0] hidden_error, hidden_inversion, hidden_err_temp1, hidden_err_temp2;
	bit[3:0][3:0][31:0] hidden_correction;
	bit[3:0][31:0] hidden_correc_temp;
	bit[3:0][31:0] out_correction;
	bit[31:0] out_error_temp;

	// Stored error values
	bit[31:0] stored_output_error;
	bit[3:0][31:0] stored_hidden_error;

	assign last_train = (address - 2) == numTrain;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            numTest <= 0;
            numTrain <= 0;
            learn_rate <= 32'h0000_4000; // 0.25
            address <= 11'd0;
            test_output <= 32'd0;
        	for (int i=0; i < 4; i++) begin
				for (int l=0; l < 4; l++) begin
            		stored_hidden_weights[i][l] <= iw;
            		end
            	stored_output_weights[i] <= iw;
           		end
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
            			stored_hidden_weights[i][l] <=
            				stored_hidden_weights[i][l] + hidden_correction[i][l];
            			end
            		stored_output_weights[i] <= 
            			stored_output_weights[i] + out_correction[i];
            		end
            	end
            if (load_output) begin
            	stored_hidden_outputs <= hidden_outputs;
            	stored_final_output <= final_output;
            	end
            if (load_oerror) begin
            	stored_output_error <= output_error;
            	end
            if (load_herror) begin
            	stored_hidden_error <= hidden_error;
            	end
           	if (inc_address) begin
           		address <= address +1;
           		end
            if (rst_address) begin
            	address <= 11'd2;
            	end
            if (store_test_out) begin
            	test_output <= stored_final_output;
            	end
            if (ready_to_test) begin
            	test_output <= 32'hD00D_B00B;
            	end
            end
        end

	neuralFSM NFSM(.*);

	always_comb begin
		for (int k=0; k<4; k++) begin: ADDER_OUTER
				hidden_sums[k] = hidden_products[0][k] + 
								 hidden_products[1][k] +
								 hidden_products[2][k] +
								 hidden_products[3][k];
			end
		end

	assign final_output = output_products[0] + 
						  output_products[1] +
						  output_products[2] +
						  output_products[3];

	// Create all of the hidden outputs and sums
	genvar k, j;
	generate
		for (k=0; k<4; k++) begin: HID_MULTS_OUTER
			for (j=0; j < 4; j++) begin: HID_MULTS_INNER
				fixed_point_multiplier HIDMULT(
					.dataa(stored_hidden_weights[k][j]),
					.datab(input_values[k]),
					.result(hidden_products[k][j]));
			end

			// Perform activation function on sum
			sigmoid sigm(
				.data(hidden_sums[k]),
				.result(hidden_outputs[k]));

			fixed_point_multiplier OUTMULT(
				.dataa(hidden_outputs[k]),
				.datab(stored_output_weights[k]),
				.result(output_products[k]));
		end
	endgenerate

	// Generate the error function
	assign output_diff = input_values[4] - stored_final_output;
	assign output_inversion = 32'h0001_0000 - stored_final_output;
	fixed_point_multiplier OERR_MULT(
		.dataa(output_diff),
		.datab(output_inversion),
		.result(output_err_temp));
	fixed_point_multiplier OERR_FINAL_MULT(
		.dataa(output_err_temp),
		.datab(stored_final_output),
		.result(output_error));
	
	// Generate the hidden error functions
	always_comb begin
		for (int i = 0; i < 4; i++) begin
			hidden_inversion[i] = 1 - stored_hidden_outputs[i];
		end
	end

	generate
		for (k=0; k<4; k++) begin: HID_ERRORS
			fixed_point_multiplier HERR_TEMP1(
				.dataa(stored_hidden_outputs[k]),
				.datab(hidden_inversion[k]),
				.result(hidden_err_temp1[k]));

			fixed_point_multiplier HERR_TEMP2(
				.dataa(stored_output_error),
				.datab(stored_output_weights[k]),
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
				.datab(stored_hidden_error[k]),
				.result(hidden_correc_temp[k]));

			for (j=0; j < 4; j++) begin: HID_NEW_INNER
				fixed_point_multiplier HID_CORRECT_TEMP1(
					.dataa(hidden_correc_temp[k]),
					.datab(input_values[j]),
					.result(hidden_correction[k][j]));
			end
		end
	endgenerate

	fixed_point_multiplier out_correc(
		.dataa(learn_rate),
		.datab(stored_output_error),
		.result(out_error_temp));
	// Create new values for output weights
	generate
		for (k=0; k<4; k++) begin: OUT_NEW
			fixed_point_multiplier HID_CORRECT_TEMP1(
				.dataa(out_error_temp),
				.datab(stored_hidden_outputs[k]),
				.result(out_correction[k]));
		end
	endgenerate

endmodule: neuralProcessor

module neuralFSM (
	input  bit  clk, rst, train, test, last_train,
	output bit  load_num_train,
				load_num_test,
				load_mem, 
				load_output,
				load_oerror,
				load_herror,
				load_new_weights,
				inc_address,
				rst_address,
				store_test_out,
				ready_to_test,
	output bit[2:0] input_sel
);

	logic[7:0] numIterations;
	bit dec_iterations;
	bit training_mode, load_mode;
	bit inc_input_sel;
	enum logic[3:0] {START1, START2, INIT1, INIT2, WAIT, HOLD, LOADING, LOADED_DATA, LOADED_OUT,
					 O_ERR_CALCED, H_ERR_CALCED, DATUM_DONE, 
					 LOADED_TEST, LOADED_TEST_OUT} cs, ns;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            cs <= START1;
            numIterations <= 8'd200;
            input_sel <= 3'd0;
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
            if (inc_input_sel) begin
            	input_sel <= input_sel == 5 ? 0 : input_sel + 1;
            	end
        	end
        end

    always_comb begin
    	load_num_train = 'b0;
    	load_num_test = 'b0;
        load_mem = 'b0;
        load_output = 'b0;
        load_oerror = 'b0;
        load_herror = 'b0;
        load_new_weights = 'b0;
        dec_iterations = 'b0;
        store_test_out = 'b0;
        ready_to_test = 'b0;
        inc_address = 'b0;
        rst_address = 'b0;
        load_mode = 'b0;
        inc_input_sel = 'b0;
        case (cs) 
        	START1: begin
        		ns = START2;
        		inc_address = 'b1;
        		end
        	START2: begin
        		ns = INIT1;
        		end
            INIT1: begin
                ns = INIT2;
                load_num_train = 'b1;
                end
            INIT2: begin
                ns = WAIT;
                load_num_test = 'b1;
                rst_address = 'b1;
                end
            WAIT:  begin
                ns = (train | test) ? HOLD : WAIT;
                inc_address = train | test;
                load_mode = 'b1;
                end
            HOLD: begin
            	ns = LOADING;
            	inc_address = 'b1;
            	end
            LOADING: begin
            	ns = input_sel == 5 ? LOADED_DATA : LOADING;
            	inc_input_sel = 'b1;
            	load_mem = 'b1;
            	inc_address = input_sel < 3;
            	end
            LOADED_DATA: begin
            	ns = training_mode ? LOADED_OUT : LOADED_TEST;
            	load_output = 'b1;
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
	        	ns = last_train && numIterations == 0 ? WAIT : HOLD;
	        	rst_address = last_train && numIterations != 0;
	        	load_mem = ~(last_train && numIterations == 0);
	        	inc_input_sel = ~(last_train && numIterations == 0);
	        	inc_address = ~(last_train && numIterations == 0);
	        	dec_iterations = 'b1;
	        	ready_to_test = last_train && numIterations == 0;
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