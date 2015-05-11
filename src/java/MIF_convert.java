import java.util.*;
import java.io.*;

public class MIF_convert {
    public static void main(String[] args) throws Exception{
	File fout = new File("love.data");
	FileOutputStream fos = new FileOutputStream(fout);
	BufferedWriter test = new BufferedWriter(new OutputStreamWriter(fos));

	fout = new File("train");
	fos = new FileOutputStream(fout);
	BufferedWriter train = new BufferedWriter(new OutputStreamWriter(fos));

	PrintWriter dev = new PrintWriter(new FileWriter("dev"));
	String label = "Tone,Eye Contact,Body Language,Proximity,Hit?";
	train.write(label); train.newLine();
	System.out.println(label);

	test.write("200 4 1");
	test.newLine();
	PrintWriter writer = new PrintWriter("data.mif", "UTF-8");
	writer.println("DEPTH = 302;");
	writer.println("WIDTH = 32;");
	writer.println("ADDRESS_RADIX = HEX;");
	writer.println("DATA_RADIX = HEX;");
	writer.println();
	writer.println("CONTENT BEGIN");
	writer.println();
	
	double[] parameters = new double[4];

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

	for(int i = 0; i < 210; i++) {
	    double sum = 0;
	    for(int j = 0; j < 4; j++) {
		values[j] = rand.nextDouble();
		val = String.format("%08X", (int)(values[j] * 65536)).toLowerCase();
		index = String.format("%03X", size).toLowerCase();
		if (i < 200)
		    test.write(values[j] + " ");
		if (i < 200)
		    train.write(values[j] + ",");
		else
		    System.out.print(values[j] + ",");

		writer.println(index + " : " + val + ";");    
		size++;
		sum += values[j] * parameters[j];
	    }
	    if (sum < .5)
		output = 0;
	    else 
		output = 1;

	    if (i < 200) {		
		val = String.format("%08X", (int)(output * 65536)).toLowerCase();
		index = String.format("%03X", size).toLowerCase();
		writer.println(index + " : " + val + ";");
		train.write(output + "");
		train.newLine();
		test.newLine();
		test.write(output + "");
		test.newLine();
	    }
	    else {
		System.out.print(output);
		System.out.println();
	    }
	}
    }    
}
	
