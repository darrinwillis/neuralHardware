    module SevenSegmentDigit
        (input  logic [3:0] bch,
        output  logic [6:0] segment,
        input logic         blank);

        logic [6:0] decoded;

        BCHtoSevenSegment b2ss(bch, decoded);

        assign segment = blank ? 7'b1111111 : decoded;

    endmodule: SevenSegmentDigit

    module SevenSegmentDigitTestBench
        (output logic [3:0] bch,
        input   logic [6:0] segment,
        output logic        blank);

        initial begin
            $display("Starting tests for SevenSegmentDigit");
            bch = 4'd0;
            blank = 0;
            #10 if (segment != 7'b1000000)
                $display("incorrect output at input 0, not blank");

            bch = 4'd0;
            blank = 1;
            #10 if (segment != 7'b1111111)
                $display("incorrect output at input 0, blank");

            bch = 4'd5;
            blank = 0;
            #10 if (segment != 7'b0010010)
                $display("incorrect output at input 5, not blank");

            bch = 4'd5;
            blank = 1;
            #10 if (segment != 7'b1111111)
                $display("incorrect output at input 5, blank");

            bch = 4'd8;
            blank = 0;
            #10 if (segment != 7'b0000000)
                $display("incorrect output at input 8, not blank");

            bch = 4'd8;
            blank = 1;
            #10 if (segment != 7'b1111111)
                $display("incorrect output at input 8, blank");
            $display("Finished tests for SevenSegmentDigit");
        end
    endmodule: SevenSegmentDigitTestBench

    module ssdtop;
        logic [3:0] bch;
        logic [6:0] segment;
        logic       blank;

        SevenSegmentDigit(.*);
        SevenSegmentDigitTestBench(.*);

    endmodule: ssdtop
