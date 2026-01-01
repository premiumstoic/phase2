module tb_mastermind;

    // --- Inputs & Outputs ---
    reg clk, rst, enterA, enterB;
    reg [2:0] letterIn;
    wire [7:0] LEDreg;
    wire [7:0] SSD3, SSD2, SSD1, SSD0;

    // --- Instantiate DUT (Device Under Test) ---
    mastermind uut (
        .clk(clk), 
        .rst(rst), 
        .enterA(enterA), 
        .enterB(enterB), 
        .letterIn(letterIn), 
        .LEDreg(LEDreg), 
        .SSD3(SSD3), 
        .SSD2(SSD2), 
        .SSD1(SSD1), 
        .SSD0(SSD0)
    );

    // --- Clock Parameters ---
    parameter HP = 250;  // Half period
    parameter FP = 500;  // Full period (2*HP)

    // --- Clock Generation ---
    always #HP clk = ~clk;

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("mastermind_wave.vcd");
        $dumpvars(0, tb_mastermind);
        
        $display("Simulation started.");
        
        clk = 1;
        rst = 1; 
        enterA = 0; 
        enterB = 0; 
        letterIn = 0;

        #HP; rst = 0; #FP; rst = 1; #FP;

        // ROUND 1: A is Maker, B guesses CORRECTLY
        enterA = 1; #FP; enterA = 0; #FP;
        #5000;
        
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b001; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b010; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b011; enterA = 1; #FP; enterA = 0; #FP;

        #5000;

        letterIn = 3'b100; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b001; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b010; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b011; enterB = 1; #FP; enterB = 0; #FP;

        #2000; enterB = 1; #FP; enterB = 0; #FP;
        #3000;

        // ROUND 2: B is Maker, A guesses WRONG then CORRECT
        #6000;

        letterIn = 3'b101; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b101; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b101; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b101; enterB = 1; #FP; enterB = 0; #FP;

        #5000;

        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;

        #2000; enterA = 1; #FP; enterA = 0; #FP;
        #1000;

        letterIn = 3'b101; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b101; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b101; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b101; enterA = 1; #FP; enterA = 0; #FP;

        #2000; enterA = 1; #FP; enterA = 0; #FP;
        #3000;

        // ROUND 3: A is Maker, B guesses CORRECTLY
        #6000;

        letterIn = 3'b111; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b111; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b111; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b111; enterA = 1; #FP; enterA = 0; #FP;

        #5000;

        letterIn = 3'b111; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b111; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b111; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b111; enterB = 1; #FP; enterB = 0; #FP;

        #2000; enterB = 1; #FP; enterB = 0; #FP;
        #3000;

        #3000;

        // TEST: INPUT ISOLATION
        #FP; rst = 0; #FP; rst = 1; #FP;

        enterA = 1; #FP; enterA = 0; #FP;
        #5000;

        enterB = 1; #FP; enterB = 0; #FP;

        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;

        #5000;

        // TEST: FULL LOSS
        letterIn = 3'b001; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b001; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b001; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b001; enterB = 1; #FP; enterB = 0; #FP;

        #2000; enterB = 1; #FP; enterB = 0; #FP;

        letterIn = 3'b010; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b010; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b010; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b010; enterB = 1; #FP; enterB = 0; #FP;

        #2000; enterB = 1; #FP; enterB = 0; #FP;

        letterIn = 3'b011; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b011; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b011; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b011; enterB = 1; #FP; enterB = 0; #FP;

        #2000; enterB = 1; #FP; enterB = 0; #FP;
        #3000;

        $display("Simulation finished.");
        $finish;
    end
endmodule
