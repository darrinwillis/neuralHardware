/*
Fast Artificial Neural Network Library (fann)
Copyright (C) 2003-2012 Steffen Nissen (sn@leenissen.dk)

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <stdio.h>
#include <math.h>
#include "fann.h"
#include "cycleTimer.h"

int FANN_API test_callback(struct fann *ann, struct fann_train_data *train,
	unsigned int max_epochs, unsigned int epochs_between_reports, 
	float desired_error, unsigned int epochs)
{
	printf("Epochs     %8d. MSE: %.5f. Desired-MSE: %.5f\n", epochs, fann_get_MSE(ann), desired_error);
	return 0;
}

int main()
{
  long start = clock();
  double startTime = CycleTimer::currentSeconds();
	fann_type *calc_out;
	const unsigned int num_input = 4;
	const unsigned int num_output = 1;
	const unsigned int num_layers = 3;
	const unsigned int num_neurons_hidden = 4;
	const float desired_error = (const float) 0;
	const unsigned int max_epochs = 200;
	const unsigned int epochs_between_reports = 10;
	struct fann *ann;
	struct fann_train_data *data;

	unsigned int i = 0;
	unsigned int decimal_point;

	printf("Creating network.\n");
	ann = fann_create_standard(num_layers, num_input, num_neurons_hidden, num_output);

	data = fann_read_train_from_file("love.data");

	fann_set_activation_steepness_hidden(ann, 1);
	fann_set_activation_steepness_output(ann, 1);

	fann_set_activation_function_hidden(ann, FANN_SIGMOID_SYMMETRIC);
	fann_set_activation_function_output(ann, FANN_SIGMOID_SYMMETRIC);

	fann_set_train_stop_function(ann, FANN_STOPFUNC_BIT);
	fann_set_bit_fail_limit(ann, 0.01f);

	fann_set_training_algorithm(ann, FANN_TRAIN_RPROP);

	fann_init_weights(ann, data);

	long setup = clock();
	printf("Setup took %lu clocks\n", setup - start);
	printf("Training network.\n");
	fann_train_on_data(ann, data, max_epochs, epochs_between_reports, desired_error);

	long end = clock();
	double endTime = CycleTimer::currentSeconds();
	printf("Training took %lu clocks, total: %lu clocks\n", end - setup, end - start);
	printf("Total:   %.3f ms\n", 1000.f * (endTime - startTime));
	//	printf("Testing network. %f\n", fann_test_data(ann, data));

	for(i = 0; i < fann_length_train_data(data); i++)
	{
	  calc_out = fann_run(ann, data->input[i]);
	  calc_out[0] = round(calc_out[0]);
	  /*printf("LOVE test (%f,%f,%f,%f) -> %f, should be %f, difference=%f\n",
		 data->input[i][0], data->input[i][1], data->input[i][2], data->input[i][3],
		 calc_out[0], data->output[i][0], fann_abs(calc_out[0] - data->output[i][0]));*/
	}

	//	printf("Saving network.\n");

	fann_save(ann, "love_float.net");

	decimal_point = fann_save_to_fixed(ann, "love_fixed.net");
	fann_save_train_to_fixed(data, "love_fixed.data", decimal_point);

	printf("Cleaning up.\n");
	fann_destroy_train(data);
	fann_destroy(ann);

	return 0;
}
