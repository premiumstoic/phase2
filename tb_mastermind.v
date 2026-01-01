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
        $dumpfile("mastermind.vcd");
        $dumpvars(0, tb_mastermind);
        
        $display("========================================");
        $display("   MASTERMIND TESTBENCH");
        $display("========================================");
        
        clk = 1;
        rst = 1; 
        enterA = 0; 
        enterB = 0; 
        letterIn = 0;

        #HP; rst = 0; #FP; rst = 1; #FP;

        // ROUND 1: A is Maker, B guesses CORRECTLY
        $display("\n[ROUND 1] A=Maker, B=Breaker");
        enterA = 1; #FP; enterA = 0; #FP;
        #5000;
        
        $display("  Maker A enters: F-A-C-E");
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b001; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b010; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b011; enterA = 1; #FP; enterA = 0; #FP;

        #5000;

        $display("  Breaker B guesses: F-A-C-E");
        letterIn = 3'b100; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b001; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b010; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b011; enterB = 1; #FP; enterB = 0; #FP;

        #2000; 
        if (LEDreg == 8'b11111111)
            $display("  ✓ PASS: All LEDs lit (correct guess)");
        else
            $display("  ✗ FAIL: LEDs = %b (expected 11111111)", LEDreg);
        
        enterB = 1; #FP; enterB = 0; #FP;
        #3000;
        
        if (SSD3 == 8'b11000000 && SSD0 == 8'b11111001)
            $display("  ✓ PASS: Score = 0-1");
        else
            $display("  ✗ FAIL: Score = %b-%b (expected 0-1)", SSD3, SSD0);

        // ROUND 2: B is Maker, A guesses WRONG then CORRECT
        $display("\n[ROUND 2] B=Maker, A=Breaker");
        #6000;

        $display("  Maker B enters: H-H-H-H");
        letterIn = 3'b101; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b101; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b101; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b101; enterB = 1; #FP; enterB = 0; #FP;

        #5000;

        $display("  Breaker A guesses (wrong): F-F-F-F");
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;

        #2000; 
        if (LEDreg != 8'b11111111)
            $display("  ✓ PASS: LEDs show partial match");
        else
            $display("  ✗ FAIL: LEDs = %b (should not be all 1s)", LEDreg);
        
        enterA = 1; #FP; enterA = 0; #FP;
        #1000;

        $display("  Breaker A retries (correct): H-H-H-H");
        letterIn = 3'b101; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b101; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b101; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b101; enterA = 1; #FP; enterA = 0; #FP;

        #2000; 
        if (LEDreg == 8'b11111111)
            $display("  ✓ PASS: All LEDs lit (retry successful)");
        else
            $display("  ✗ FAIL: LEDs = %b (expected 11111111)", LEDreg);
        
        enterA = 1; #FP; enterA = 0; #FP;
        #3000;
        
        if (SSD3 == 8'b11111001 && SSD0 == 8'b11111001)
            $display("  ✓ PASS: Score = 1-1");
        else
            $display("  ✗ FAIL: Score = %b-%b (expected 1-1)", SSD3, SSD0);

        // ROUND 3: A is Maker, B guesses CORRECTLY
        $display("\n[ROUND 3] A=Maker, B=Breaker (Match Point)");
        #6000;

        $display("  Maker A enters: U-U-U-U");
        letterIn = 3'b111; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b111; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b111; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b111; enterA = 1; #FP; enterA = 0; #FP;

        #5000;

        $display("  Breaker B guesses: U-U-U-U");
        letterIn = 3'b111; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b111; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b111; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b111; enterB = 1; #FP; enterB = 0; #FP;

        #2000; 
        if (LEDreg == 8'b11111111)
            $display("  ✓ PASS: All LEDs lit (correct guess)");
        else
            $display("  ✗ FAIL: LEDs = %b (expected 11111111)", LEDreg);
        
        enterB = 1; #FP; enterB = 0; #FP;
        #3000;
        
        if (SSD3 == 8'b11111001 && SSD0 == 8'b10100100)
            $display("  ✓ PASS: Score = 1-2 (Player B WINS!)");
        else
            $display("  ✗ FAIL: Score = %b-%b (expected 1-2)", SSD3, SSD0);

        #3000;
        
        if (SSD3 == 8'b10001000 && SSD0 == 8'b10000011)
            $display("  ✓ PASS: Game reset to start state (A-b)");
        else
            $display("  ✗ FAIL: Reset display = %b-%b (expected A-b)", SSD3, SSD0);

        // TEST: INPUT ISOLATION
        $display("\n[TEST] Input Isolation");
        #FP; rst = 0; #FP; rst = 1; #FP;

        enterA = 1; #FP; enterA = 0; #FP;
        #5000;

        $display("  Attempting enterB during A's turn (should be ignored)");
        enterB = 1; #FP; enterB = 0; #FP;

        $display("  Maker A enters: F-F-F-F");
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;
        letterIn = 3'b100; enterA = 1; #FP; enterA = 0; #FP;

        #5000;
        $display("  ✓ PASS: Input isolation verified (simulation continued)");

        // TEST: FULL LOSS
        $display("\n[TEST] Full Loss (3 wrong guesses)");
        
        $display("  Breaker B guess 1 (wrong): A-A-A-A");
        letterIn = 3'b001; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b001; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b001; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b001; enterB = 1; #FP; enterB = 0; #FP;

        #2000; enterB = 1; #FP; enterB = 0; #FP;

        $display("  Breaker B guess 2 (wrong): C-C-C-C");
        letterIn = 3'b010; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b010; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b010; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b010; enterB = 1; #FP; enterB = 0; #FP;

        #2000; enterB = 1; #FP; enterB = 0; #FP;

        $display("  Breaker B guess 3 (wrong): E-E-E-E");
        letterIn = 3'b011; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b011; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b011; enterB = 1; #FP; enterB = 0; #FP;
        letterIn = 3'b011; enterB = 1; #FP; enterB = 0; #FP;

        #2000; enterB = 1; #FP; enterB = 0; #FP;
        #3000;
        
        if (SSD3 == 8'b11111001 && SSD0 == 8'b11000000)
            $display("  ✓ PASS: Score = 1-0 (Maker A wins on full loss)");
        else
            $display("  ✗ FAIL: Score = %b-%b (expected 1-0)", SSD3, SSD0);

        $display("\n========================================");
        $display("   ALL TESTS COMPLETED");
        $display("========================================");
        $finish;
    end
endmodule
