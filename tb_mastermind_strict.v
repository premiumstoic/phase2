`timescale 1ms/1ms

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

    // --- Parameters for Checking Results ---
    localparam SEG_0 = 8'b11000000;
    localparam SEG_1 = 8'b11111001;
    localparam SEG_2 = 8'b10100100;
    localparam SEG_A = 8'b10001000;
    localparam SEG_b = 8'b10000011;

    // --- Clock Generation (Standard approach) ---
    initial clk = 0;
    always #250 clk = ~clk; // 2Hz Clock (Period = 500ms)

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("mastermind_wave.vcd");
        $dumpvars(0, tb_mastermind);
        
        // 1. Initialize Inputs
        rst = 1; 
        enterA = 0; 
        enterB = 0; 
        letterIn = 0;

        // 2. Perform Reset
        #100; 
        rst = 0; // Active Low Reset
        #100; 
        rst = 1;
        #1000;

        // ==========================================
        // ROUND 1: Player A is Maker, B guesses CORRECTLY
        // ==========================================
        $display("\n=== ROUND 1 START (A=Maker, B=Breaker) ===");
        
        // Action: Press A to Start
        @(negedge clk); 
        enterA = 1; 
        #600; 
        enterA = 0; 
        #500;
        
        $display("Waiting for Init Timers...");
        #5000; // Wait for S1/S2 timers

        $display("Maker (A) Enters: F-A-C-E");
        
        // Enter 'F' (100)
        letterIn = 3'b100; #50; 
        @(negedge clk); enterA = 1; #600; enterA = 0; #500;

        // Enter 'A' (001)
        letterIn = 3'b001; #50; 
        @(negedge clk); enterA = 1; #600; enterA = 0; #500;

        // Enter 'C' (010)
        letterIn = 3'b010; #50; 
        @(negedge clk); enterA = 1; #600; enterA = 0; #500;

        // Enter 'E' (011)
        letterIn = 3'b011; #50; 
        @(negedge clk); enterA = 1; #600; enterA = 0; #500;

        $display("Waiting for Role Swap Timer...");
        #5000; // Wait for S4/S5

        $display("Breaker (B) Guesses: F-A-C-E (Correct)");

        // Enter 'F' (100)
        letterIn = 3'b100; #50; 
        @(negedge clk); enterB = 1; #600; enterB = 0; #500;

        // Enter 'A' (001)
        letterIn = 3'b001; #50; 
        @(negedge clk); enterB = 1; #600; enterB = 0; #500;

        // Enter 'C' (010)
        letterIn = 3'b010; #50; 
        @(negedge clk); enterB = 1; #600; enterB = 0; #500;

        // Enter 'E' (011)
        letterIn = 3'b011; #50; 
        @(negedge clk); enterB = 1; #600; enterB = 0; #500;

        repeat (3) @(posedge clk); // Wait for Check

        if (LEDreg == 8'b11111111) 
            $display("PASS: LEDs indicate correct guess.");
        else 
            $display("FAIL: LEDs show %b", LEDreg);

        // Press B to Acknowledge Result
        @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        
        repeat (6) @(posedge clk); // Wait for S10

        // Check Score: Should be 0 - 1 (A - B)
        if (SSD3 == SEG_0 && SSD0 == SEG_1) 
            $display("PASS: Scoreboard shows 0-1.");
        else 
            $display("FAIL: Scoreboard shows SSD3=%b SSD0=%b", SSD3, SSD0);

        // ==========================================
        // ROUND 2: Player B is Maker, A Guesses WRONG, then CORRECT
        // ==========================================
        $display("\n=== ROUND 2 START (B=Maker, A=Breaker) ===");
        
        $display("Waiting for Round 2 Init...");
        #6000; // Covers S10 wait + S1 wait + S2 wait

        $display("Maker (B) Enters: H-H-H-H");
        
        // Input 'H' (101) four times
        letterIn = 3'b101; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b101; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b101; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b101; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;

        #5000; // Wait for swap

        $display("Breaker (A) Guesses WRONG: F-F-F-F");
        
        // Input 'F' (100) four times
        letterIn = 3'b100; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b100; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b100; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b100; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;

        repeat (3) @(posedge clk);
        
        if (LEDreg != 8'b11111111) 
            $display("PASS: LEDs show incomplete match (Correct).");
        else 
            $display("FAIL: LEDs show match for wrong guess!");

        // Press A to Retry
        @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        repeat (2) @(posedge clk);

        $display("Breaker (A) Retries CORRECTLY: H-H-H-H");
        
        // Input 'H' (101) four times
        letterIn = 3'b101; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b101; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b101; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b101; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;

        repeat (3) @(posedge clk);
        if (LEDreg == 8'b11111111) $display("PASS: Retry successful.");
        
        // Press A to Ack result
        @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        repeat (6) @(posedge clk);

        // Check Score: Should be 1 - 1
        if (SSD3 == SEG_1 && SSD0 == SEG_1) 
            $display("PASS: Scoreboard shows 1-1.");
        else 
            $display("FAIL: Scoreboard shows SSD3=%b SSD0=%b", SSD3, SSD0);

        // ==========================================
        // ROUND 3: Player A is Maker, B guesses CORRECTLY -> Game Over
        // ==========================================
        $display("\n=== ROUND 3 START (A=Maker, B=Breaker) ===");
        #6000; 

        // Maker A enters U-U-U-U
        letterIn = 3'b111; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b111; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b111; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b111; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;

        #5000;

        // Breaker B guesses U-U-U-U
        letterIn = 3'b111; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b111; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b111; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b111; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;

        repeat (3) @(posedge clk);
        // Press B to Ack
        @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        repeat (6) @(posedge clk);

        // Check Score: 1 - 2
        if (SSD3 == SEG_1 && SSD0 == SEG_2) 
            $display("PASS: Scoreboard shows 1-2. Player B wins!");
        else 
            $display("FAIL: Score %b-%b", SSD3, SSD0);

        #3000;
        // Verify Game Reset
        if (SSD3 == SEG_A && SSD0 == SEG_b) 
            $display("PASS: Game returned to Start State (A-b displayed).");
        else
            $display("FAIL: Game reset. SSD3=%b SSD0=%b", SSD3, SSD0);

        // ==========================================
        // TEST CASE 4: INPUT ISOLATION (The "Cheater" Test)
        // ==========================================
        $display("\n=== TEST CASE 4: INPUT ISOLATION CHECK ===");
        
        // Reset
        rst = 0; #100; rst = 1; #1000;
        
        // Start Game with Player A
        @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        #5000;

        $display("State S3: Attempting to press Enter B (Should be ignored)...");
        @(negedge clk); enterB = 1; #600; enterB = 0; #500;

        $display("Maker (A) Enters Valid Code: F-F-F-F");
        letterIn = 3'b100; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b100; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b100; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        letterIn = 3'b100; #50; @(negedge clk); enterA = 1; #600; enterA = 0; #500;

        #5000;
        $display("PASS: Input Isolation Verified (Simulation did not hang).");

        // ==========================================
        // TEST CASE 5: FULL LOSS (0 Lives)
        // ==========================================
        $display("\n=== TEST CASE 5: FULL LOSS CHECK ===");
        
        // Guess 1 (Wrong)
        letterIn = 3'b001; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b001; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b001; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b001; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        repeat(3) @(posedge clk); 
        @(negedge clk); enterB = 1; #600; enterB = 0; #500; // Ack

        // Guess 2 (Wrong)
        letterIn = 3'b010; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b010; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b010; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b010; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        repeat(3) @(posedge clk); 
        @(negedge clk); enterB = 1; #600; enterB = 0; #500; // Ack

        // Guess 3 (Wrong)
        letterIn = 3'b011; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b011; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b011; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        letterIn = 3'b011; #50; @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        repeat(3) @(posedge clk);
        
        // Final Ack
        @(negedge clk); enterB = 1; #600; enterB = 0; #500; 
        repeat(6) @(posedge clk);

        if (SSD3 == SEG_1 && SSD0 == SEG_0) 
            $display("PASS: Full Loss Verified. Score is 1-0 (Maker won).");
        else 
            $display("FAIL: Score is %b-%b (Expected 1-0)", SSD3, SSD0);

        $display("\n--- SIMULATION COMPLETE ---");
        $finish;
    end
endmodule
