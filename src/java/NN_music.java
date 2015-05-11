import java.util.*;
import java.io.*;

public class NN_music {
    public final int nh = 4;
    public final double r = .2;
    public final int n = 4;
    public final int iterations = 200;

    public double[][] hw = new double[n][nh];
    public double[] ow = new double[nh];
    
    public static void main(String[] args) throws Exception{
        BufferedReader test = new BufferedReader(new FileReader(args[0]));
        String line = test.readLine();
        List<double[]> lines = new ArrayList<double[]>();

        int size = 0;
        line = test.readLine();
        while(line != null) {
            String[] words = line.split(",");
            double[] vals = new double[words.length];
	    for(int i = 0; i < words.length; i ++)
		vals[i] = Double.parseDouble(words[i]);
            lines.add(vals);
            size++;
            line = test.readLine();
        }
        
        NN_music nn = new NN_music();
        nn.BP(lines);
        System.out.println("TRAINING COMPLETED! NOW PREDICTING.");
        BufferedReader dev = new BufferedReader(new FileReader(args[1]));
        lines.clear();
        line = dev.readLine();
        line = dev.readLine();
        while(line != null) {
            String[] words = line.split(",");
            double[] vals = new double[words.length];
	    for(int i = 0; i < words.length; i ++)
		vals[i] = Double.parseDouble(words[i]);          
            lines.add(vals);
            size++;
            line = dev.readLine();
        }

        nn.run(lines);
    }
    public void run(List<double[]> dev) {
        for(double[] ex : dev) {
            double[] hid = new double[nh];
            double sum;
            for(int h = 0; h < nh; h++) {
                sum = 0;
                for(int i = 0; i < n; i++) 
                    sum += hw[i][h] * ex[i];
                hid[h] = 1/(1+Math.exp(-sum));
            }
            
            sum = 0;
            for(int h = 0; h < nh; h++) 
                sum += ow[h] * hid[h];
            
            if (.5 < 1/(1+Math.exp(-sum))) 
                System.out.println("yes");
            else 
                System.out.println("no");
        }
    }
    
    public void BP(List<double[]> test) {
        double[] hid = new double[nh];
        double[] hErr = new double[nh];
        double out;
        double oErr = 0;
        double error = 0;

        //intialize hw and ow
        Random rand = new Random();
        double sum;
        for(int i = 0; i < hw.length; i++) 
            for(int j = 0; j < hw[0].length; j++) 
                hw[i][j] = rand.nextDouble()/10;
        
        for(int i = 0; i < ow.length; i++)
            ow[i] = rand.nextDouble()/10;

        hid[0] = 1;
        
        for(int count = 0; count < iterations; count++) {
            error = 0;
            for(double[] ex : test) {
                for(int h = 0; h < nh; h++) {
                    sum = 0;
                    for(int i = 0; i < n; i++)  {
			System.out.println(hw[i][h]);
			System.out.println(ex[i]);
                        sum += hw[i][h] * ex[i];
		    }
                    hid[h] = 1/(1+Math.exp(-sum));
                }
                
                sum = 0;
                for(int h = 0; h < nh; h++) 
                    sum += ow[h] * hid[h];

                out = 1/(1+Math.exp(-sum));

                error += (out - ex[n]) * (out - ex[n]);

                oErr = out * (1 - out) * (ex[n] - out);
                
                for(int h = 0; h < nh; h++) {
                    hErr[h] = hid[h] * (1 - hid[h]) * ow[h] * oErr;
                    for(int i = 0; i < n; i++) 
                        hw[i][h] = hw[i][h] + r*hErr[h]*ex[i];
                    ow[h] = ow[h] + r*oErr*hid[h];
                }
            }
            if (count % 10 == 0) 
                System.out.println(error/2);
        }
    }
}
