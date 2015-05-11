import java.util.*;
import java.io.*;

public class MIF_convert {
    public static void main(String[] args) throws Exception{
	PrintWriter test = new PrintWriter(new FileWriter("love.data"));
	PrintWriter train = new PrintWriter(new FileWriter("train"));
	PrintWriter dev = new PrintWriter(new FileWriter("dev"));
	test.println("200 4 1");
	PrintWriter writer = new PrintWriter("data.mif", "UTF-8");
	writer.println("DEPTH = 302;");
	writer.println("WIDTH = 32;");
	writer.println("ADDRESS_RADIX = HEX;");
	writer.println("DATA_RADIX = HEX;");
	writer.println();
	writer.println("CONTENT BEGIN");
	writer.println();
	
	double[] parameters = new double[4];
	String label = "Tone,Eye Contact,Body Language,Proximity,Hit?";
	train.println(label);
	test.println(label);

	Random rand = new Random();
	parameters[0] = rand.nextDouble()/5 + .1;
	parameters[1] = rand.nextDouble()/5 + .1;
	parameters[2] = rand.nextDouble()/5 + .1;
	parameters[3] = rand.nextDouble()/5 + .1;

	double[] values = new double[4];
	double output;
	int size = 0;

	String val = 
	    String.format("%08X", 200).toLowerCase();
	String index = String.format("%03X", size).toLowerCase();
	writer.println(index + " : " + val + ";");    
	size++;

	val = String.format("%08X", 100).toLowerCase();
	index = String.format("%03X", size).toLowerCase();
	writer.println(index + " : " + val + ";");    
	size++;

	for(int i = 0; i < 300; i++) {
	    double sum = 0;
	    for(int j = 0; j < 4; j++) {
		values[j] = rand.nextDouble();
		val = String.format("%08X", (int)(values[j] * 65536)).toLowerCase();
		index = String.format("%03X", size).toLowerCase();
		if (i < 200)
		    test.print(values[j] + " ");
		if (i < 200)
		    train.print(values[j] + ",");
		else
		    dev.print(values[j] + ",");

		writer.println(index + " : " + val + ";");    
		size++;
		sum += values[j] * parameters[j];
	    }
	    if (i < 200) {
		if (sum < .5)
		    output = 0;
		else 
		    output = 1;
		
		val = String.format("%08X", (int)(output * 65536)).toLowerCase();
		index = String.format("%03X", size).toLowerCase();
		writer.println(index + " : " + val + ";");
		train.print(output);
		train.println();
		test.println();
		test.print(output);
		test.println();
	    }
	    else {
		dev.print(output);
		dev.println();
	    }
	}
    }    
}
	
