    module BCHtoSevenSegment
        (input  logic [3:0] bch,
        output  logic [6:0] segment);

        always_comb
            case(bch)
                4'h0: segment = 7'b1000000; //0
                4'h1: segment = 7'b1111001; //1
                4'h2: segment = 7'b0100100; //2
                4'h3: segment = 7'b0110000; //3
                4'h4: segment = 7'b0011001; //4
                4'h5: segment = 7'b0010010; //5
                4'h6: segment = 7'b0000010; //6
                4'h7: segment = 7'b1111000; //7
                4'h8: segment = 7'b0000000; //8
                4'h9: segment = 7'b0010000; //9
                4'ha: segment = 7'b0001000; //a
                4'hb: segment = 7'b0000011; //b
                4'hc: segment = 7'b1000110; //c
                4'hd: segment = 7'b0100001; //d
                4'he: segment = 7'b0000110; //e
                4'hf: segment = 7'b0001110; //f
                default: segment = 7'b0000000;
            endcase
    endmodule: BCHtoSevenSegment

    module BCHtoSevenSegmentTestBench
        (output  logic [3:0] bch,
        input  logic [6:0] segment);

        initial begin
            bch = 4'd0;

            $display("Starting tests");
            // 0
            #10 if (segment != 7'b1000000)
                $display("incorrect output at input 0");

            bch = 4'd1;
            #10 if (segment != 7'b1111001)
                $display("incorrect output at input 1");

            bch = 4'd2;
            #10 if (segment != 7'b0100100)
                $display("incorrect output at input 2");
            
            bch = 4'd3;
            #10 if (segment != 7'b0110000)
                $display("incorrect output at input 3");
            
            bch = 4'd4;
            #10 if (segment != 7'b0011001)
                $display("incorrect output at input 4");
            
            bch = 4'd5;
            #10 if (segment != 7'b0010010)
                $display("incorrect output at input 5");
            
            bch = 4'd6;
            #10 if (segment != 7'b0000010)
                $display("incorrect output at input 6");
            
            bch = 4'd7;
            #10 if (segment != 7'b1111000)
                $display("incorrect output at input 7");
            
            bch = 4'd8;
            #10 if (segment != 7'b0000000)
                $display("incorrect output at input 8");
            
            bch = 4'd9;
            #10 if (segment != 7'b0010000)
                $display("incorrect output at input 9");
            $display("Finished tests");
        end

    endmodule: BCHtoSevenSegmentTestBench

    module top;
        logic [3:0] bch;
        logic [6:0] segment;
        
        BCHtoSevenSegment(.*);
        BCHtoSevenSegmentTestBench(.*);

    endmodule: top
