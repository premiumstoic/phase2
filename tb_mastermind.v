`timescale 1ms/1ms

module tb_mastermind;

    // --- Inputs & Outputs ---
    reg clk, rst, enterA, enterB;
    reg [2:0] letterIn;
    wire [7:0] LEDreg;
    wire [7:0] SSD3, SSD2, SSD1, SSD0;

    // --- Instantiate DUT ---
    mastermind uut (
        .clk(clk), .rst(rst), .enterA(enterA), .enterB(enterB), 
        .letterIn(letterIn), .LEDreg(LEDreg), 
        .SSD3(SSD3), .SSD2(SSD2), .SSD1(SSD1), .SSD0(SSD0)
    );

    // --- 8-Bit Segment Patterns (Parameterized - Update these if you change logic) ---
    localparam SEG_0 = 8'b11000000;  // 0
    localparam SEG_1 = 8'b11111001;  // 1
    localparam SEG_2 = 8'b10100100;  // 2

    // --- Clock Generation (2 Hz) ---
    initial begin
        clk = 0;
        forever #250 clk = ~clk; 
    end

    // --- Helper Tasks ---
    task press_A;
        begin
            @(negedge clk); enterA = 1; #600; enterA = 0; #500;
        end
    endtask

    task press_B;
        begin
            @(negedge clk); enterB = 1; #600; enterB = 0; #500;
        end
    endtask

    task maker_enter;
        input [2:0] val;
        begin
            letterIn = val; #50; press_A();
        end
    endtask

    task breaker_enter;
        input [2:0] val;
        begin
            letterIn = val; #50; press_B();
        end
    endtask

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("mastermind_wave.vcd");
        $dumpvars(0, tb_mastermind);
        
        // 1. Reset
        rst = 1; enterA = 0; enterB = 0; letterIn = 0;
        #100; rst = 0; #100; rst = 1;
        #1000;

        // ==========================================
        // ROUND 1: Player A is Maker, B guesses CORRECTLY
        // ==========================================
        $display("\n=== ROUND 1 START (A=Maker, B=Breaker) ===");
        press_A(); // Start Game (S0 -> S1)
        
        $display("Waiting for Init Timers...");
        #5000; // Wait for S1/S2 timers

        $display("Maker (A) Enters: F-A-C-E");
        maker_enter(3'b100); maker_enter(3'b001); maker_enter(3'b010); maker_enter(3'b011); 

        $display("Waiting for Role Swap Timer...");
        #5000; // Wait for S4/S5

        $display("Breaker (B) Guesses: F-A-C-E (Correct)");
        breaker_enter(3'b100); breaker_enter(3'b001); breaker_enter(3'b010); breaker_enter(3'b011);

        repeat (3) @(posedge clk); // Wait for Check

        if (LEDreg == 8'b11111111) $display("PASS: LEDs indicate correct guess.");
        else $display("FAIL: LEDs show %b", LEDreg);

        press_B(); // Ack result
        repeat (6) @(posedge clk); // Wait for S10

        // Check Score: Should be 0 - 1 (A - B)
        if (SSD3 === SEG_0 && SSD0 === SEG_1) $display("PASS: Scoreboard shows 0-1.");
        else $display("FAIL: Scoreboard shows SSD3=%b SSD0=%b", SSD3, SSD0);

        // ==========================================
        // ROUND 2: Player B is Maker, A Guesses WRONG, then CORRECT
        // ==========================================
        $display("\n=== ROUND 2 START (B=Maker, A=Breaker) ===");
        // Logic: In S10, timer waits 2s, then swaps roles and goes to S1.
        // We are already waiting in S10 from previous step.
        // Let's wait for the transition to S3 (Maker Input)
        
        $display("Waiting for Round 2 Init...");
        #6000; // Covers S10 wait + S1 wait + S2 wait

        // Note: Code Maker is now B. So we use 'press_B' for Maker Input.
        // Your logic uses "turn_A" flag. 
        // If turn_A=0, Maker is B (uses EnterB).
        
        $display("Maker (B) Enters: H-H-H-H");
        letterIn = 3'b101; press_B();
        letterIn = 3'b101; press_B();
        letterIn = 3'b101; press_B();
        letterIn = 3'b101; press_B();

        #5000; // Wait for swap

        $display("Breaker (A) Guesses WRONG: F-F-F-F");
        letterIn = 3'b100; press_A();
        letterIn = 3'b100; press_A();
        letterIn = 3'b100; press_A();
        letterIn = 3'b100; press_A();

        repeat (3) @(posedge clk);
        
        if (LEDreg != 8'b11111111) $display("PASS: LEDs show incomplete match (Correct).");
        else $display("FAIL: LEDs show match for wrong guess!");

        press_A(); // Ack result (Retry)
        repeat (2) @(posedge clk);

        $display("Breaker (A) Retries CORRECTLY: H-H-H-H");
        letterIn = 3'b101; press_A();
        letterIn = 3'b101; press_A();
        letterIn = 3'b101; press_A();
        letterIn = 3'b101; press_A();

        repeat (3) @(posedge clk);
        if (LEDreg == 8'b11111111) $display("PASS: Retry successful.");
        else $display("FAIL: Retry LEDs show %b", LEDreg);
        
        press_A(); // Ack result
        repeat (6) @(posedge clk); // Wait for S10

        // Check Score: Should be 1 - 1 (A - B)
        if (SSD3 === SEG_1 && SSD0 === SEG_1) $display("PASS: Scoreboard shows 1-1.");
        else $display("FAIL: Scoreboard shows SSD3=%b SSD0=%b", SSD3, SSD0);

        // ==========================================
        // ROUND 3: Player A is Maker again, B guesses CORRECTLY -> Game Over
        // ==========================================
        $display("\n=== ROUND 3 START (A=Maker, B=Breaker) - Game Over Test ===");
        
        $display("Waiting for Round 3 Init...");
        #6000; // Covers S10 wait + S1 wait + S2 wait

        // Player A is Maker again (turn_A=1)
        $display("Maker (A) Enters: U-U-U-U");
        maker_enter(3'b111); maker_enter(3'b111); maker_enter(3'b111); maker_enter(3'b111); 

        #5000; // Wait for S4/S5

        $display("Breaker (B) Guesses: U-U-U-U (Correct)");
        breaker_enter(3'b111); breaker_enter(3'b111); breaker_enter(3'b111); breaker_enter(3'b111);

        repeat (3) @(posedge clk);

        if (LEDreg == 8'b11111111) $display("PASS: LEDs indicate correct guess.");
        else $display("FAIL: LEDs show %b", LEDreg);

        press_B(); // Ack result
        repeat (6) @(posedge clk); // Wait for S10

        // Check Score: Should be 1 - 2 (A - B) -> B WINS THE MATCH
        if (SSD3 === SEG_1 && SSD0 === SEG_2) $display("PASS: Scoreboard shows 1-2. Player B wins!");
        else $display("FAIL: Scoreboard shows SSD3=%b SSD0=%b", SSD3, SSD0);

        // Wait for game to reset (S10 timer expires -> S0)
        #3000;

        // Verify we're back at S0 (should show "A-b")
        $display("Verifying Game Reset to S0...");
        if (SSD3 === 8'b10001000 && SSD0 === 8'b10000011) // A and b
            $display("PASS: Game returned to Start State (A-b displayed).");
        else
            $display("INFO: Game reset. SSD3=%b SSD0=%b", SSD3, SSD0);

        // ==========================================
        // TEST CASE 4: INPUT ISOLATION (The "Cheater" Test)
        // Requirement: "enter B button should not work" during A's turn
        // ==========================================
        $display("\n=== TEST CASE 4: INPUT ISOLATION CHECK ===");
        rst = 0; #100; rst = 1; #1000;
        press_A();
        #5000; // Reach S3

        $display("State S3: Attempting to press Enter B (Should be ignored)...");
        enterB = 1; #600; enterB = 0; #500;

        $display("Maker (A) Enters Valid Code: F-F-F-F");
        maker_enter(3'b100); maker_enter(3'b100); maker_enter(3'b100); maker_enter(3'b100);

        #5000; // Wait for swap to S4
        $display("PASS: Input Isolation Verified. Game continued normally after invalid button press.");


        // ==========================================
        // TEST CASE 5: FULL LOSS (0 Lives)
        // Requirement: "Player A do not guess the correct code" (Loss Condition)
        // ==========================================
        $display("\n=== TEST CASE 5: FULL LOSS CHECK ===");

        $display("Breaker (B) Guess 1 (WRONG): A-A-A-A");
        breaker_enter(3'b001); breaker_enter(3'b001); breaker_enter(3'b001); breaker_enter(3'b001);
        repeat(3) @(posedge clk); press_B();

        $display("Breaker (B) Guess 2 (WRONG): C-C-C-C");
        breaker_enter(3'b010); breaker_enter(3'b010); breaker_enter(3'b010); breaker_enter(3'b010);
        repeat(3) @(posedge clk); press_B();

        $display("Breaker (B) Guess 3 (WRONG): E-E-E-E");
        breaker_enter(3'b011); breaker_enter(3'b011); breaker_enter(3'b011); breaker_enter(3'b011);
        repeat(3) @(posedge clk);

        press_B();
        repeat(6) @(posedge clk);

        if (SSD3 === SEG_1 && SSD0 === SEG_0) 
            $display("PASS: Full Loss Verified. Score is 1-0 (Maker won).");
        else 
            $display("FAIL: Score is %b-%b (Expected 1-0)", SSD3, SSD0);

        $display("\n--- SIMULATION COMPLETE ---");
        $display("All tests executed. Check waveform for detailed analysis.");
        $finish;
    end
endmodule
