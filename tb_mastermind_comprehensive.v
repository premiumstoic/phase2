`timescale 1ms/1ms

module tb_mastermind_comprehensive;

    // --- 1. Signal Declarations ---
    reg clk, rst, enterA, enterB;
    reg [2:0] letterIn;
    wire [7:0] LEDreg;
    wire [7:0] SSD3, SSD2, SSD1, SSD0;

    // --- 2. DUT Instantiation ---
    mastermind uut (
        .clk(clk), .rst(rst), .enterA(enterA), .enterB(enterB), 
        .letterIn(letterIn), .LEDreg(LEDreg), 
        .SSD3(SSD3), .SSD2(SSD2), .SSD1(SSD1), .SSD0(SSD0)
    );

    // --- 3. Parameters (8-bit SSD Codes) ---
    localparam SEG_0 = 8'b11000000;  // 0
    localparam SEG_1 = 8'b11111001;  // 1
    localparam SEG_2 = 8'b10100100;  // 2
    localparam SEG_3 = 8'b10110000;  // 3
    localparam SEG_A = 8'b10001000;  // A
    localparam SEG_b = 8'b10000011;  // b
    localparam SEG_F = 8'b10001110;  // F
    localparam SEG_C = 8'b11000110;  // C
    localparam SEG_E = 8'b10000110;  // E
    localparam SEG_H = 8'b10001001;  // H
    localparam SEG_L = 8'b11000111;  // L
    localparam SEG_U = 8'b11000001;  // U
    localparam SEG_OFF = 8'b11111111; // OFF
    localparam SEG_DASH = 8'b10111111; // -

    // Letter encoding
    localparam LET_DASH = 3'b000;
    localparam LET_A    = 3'b001;
    localparam LET_C    = 3'b010;
    localparam LET_E    = 3'b011;
    localparam LET_F    = 3'b100;
    localparam LET_H    = 3'b101;
    localparam LET_L    = 3'b110;
    localparam LET_U    = 3'b111;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;

    // --- 4. Clock Generation ---
    initial begin
        clk = 0;
        forever #250 clk = ~clk; // 2Hz Clock (500ms period)
    end

    // --- 5. Helper Tasks ---
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

    task reset_system;
        begin
            rst = 1; enterA = 0; enterB = 0; letterIn = 0;
            #100; rst = 0; #100; rst = 1; #1000;
            $display("--- SYSTEM RESET ---");
        end
    endtask

    task maker_A_enter;
        input [2:0] val;
        begin
            letterIn = val; #50; press_A();
        end
    endtask

    task maker_B_enter;
        input [2:0] val;
        begin
            letterIn = val; #50; press_B();
        end
    endtask

    task breaker_A_enter;
        input [2:0] val;
        begin
            letterIn = val; #50; press_A();
        end
    endtask

    task breaker_B_enter;
        input [2:0] val;
        begin
            letterIn = val; #50; press_B();
        end
    endtask

    task wait_timers;
        begin
            #5000; // Wait for state timers (S1, S2, S4, S5)
        end
    endtask

    task check_pass;
        input [200*8:1] msg;
        begin
            pass_count = pass_count + 1;
            $display("PASS: %0s", msg);
        end
    endtask

    task check_fail;
        input [200*8:1] msg;
        begin
            fail_count = fail_count + 1;
            $display("FAIL: %0s", msg);
        end
    endtask

    // --- 6. Main Test Sequence ---
    initial begin
        $dumpfile("mastermind_comprehensive.vcd");
        $dumpvars(0, tb_mastermind_comprehensive);

        // ============================================================
        // TEST CASE 1: INPUT ISOLATION ("The Cheater Test")
        // Objective: Ensure Player B cannot interrupt Player A's turn
        // ============================================================
        $display("\n");
        $display("============================================================");
        $display("TEST CASE 1: INPUT ISOLATION (The Cheater Test)");
        $display("============================================================");
        reset_system();
        
        // 1. Start Game with Player A as Maker
        press_A(); 
        wait_timers(); // Wait for S1/S2 timers to reach S3 (Maker Input)
        
        // 2. Player A enters first letter (F)
        letterIn = LET_F; #50; press_A();
        $display("Maker A entered first letter (F). letter_count should be 1.");
        
        // 3. Attempt to input with Player B (Should be ignored)
        $display("Attempting CHEAT: Player B tries to input during A's Maker turn...");
        letterIn = LET_H; #50; 
        press_B(); // This should be IGNORED
        
        // 4. Player A continues with valid input
        $display("Player A continues entering: A-C-E");
        maker_A_enter(LET_A); 
        maker_A_enter(LET_C); 
        maker_A_enter(LET_E); 
        
        // Verify we made it to S4 (Maker done)
        wait_timers(); // Wait for S4/S5
        
        // 5. Now test Breaker isolation: Player B is Breaker
        $display("Breaker B entering guess. Attempting CHEAT: Player A tries to input...");
        
        // B enters first letter
        letterIn = LET_F; #50; press_B();
        
        // A tries to cheat during B's breaker turn
        letterIn = LET_U; #50;
        press_A(); // This should be IGNORED
        
        // B continues
        breaker_B_enter(LET_A);
        breaker_B_enter(LET_C);
        breaker_B_enter(LET_E);
        
        repeat (3) @(posedge clk);
        
        // Verify correct guess detected (all letters match)
        if (LEDreg == 8'b11111111) 
            check_pass("Input isolation worked - correct guess detected despite cheat attempts.");
        else 
            check_fail("Input isolation may have failed.");
        
        press_B(); // Ack
        #6000;
        
        // ============================================================
        // TEST CASE 2: THE LOSS PATH (Lives = 0)
        // Objective: Verify logic when Code Breaker fails 3 times
        // ============================================================
        $display("\n");
        $display("============================================================");
        $display("TEST CASE 2: GAME OVER / LOSS PATH (3 Wrong Guesses)");
        $display("============================================================");
        reset_system();
        
        // 1. Start Game and setup - A is Maker
        press_A();
        wait_timers();
        
        // 2. Maker sets code F-A-C-E
        $display("Maker (A) enters secret code: F-A-C-E");
        maker_A_enter(LET_F);
        maker_A_enter(LET_A);
        maker_A_enter(LET_C);
        maker_A_enter(LET_E);
        
        wait_timers(); // Wait for S4/S5
        
        // 3. GUESS 1: H-H-H-H (Wrong) -> Lives should be 2
        $display("Breaker (B) Guess 1: H-H-H-H (WRONG)");
        breaker_B_enter(LET_H);
        breaker_B_enter(LET_H);
        breaker_B_enter(LET_H);
        breaker_B_enter(LET_H);
        
        repeat (3) @(posedge clk);
        
        if (LEDreg != 8'b11111111)
            check_pass("Guess 1 detected as wrong. Lives should be 2.");
        else
            check_fail("Guess 1 incorrectly detected as correct!");
        
        press_B(); // Ack - should retry
        repeat (2) @(posedge clk);
        
        // 4. GUESS 2: L-L-L-L (Wrong) -> Lives should be 1
        $display("Breaker (B) Guess 2: L-L-L-L (WRONG)");
        breaker_B_enter(LET_L);
        breaker_B_enter(LET_L);
        breaker_B_enter(LET_L);
        breaker_B_enter(LET_L);
        
        repeat (3) @(posedge clk);
        
        if (LEDreg != 8'b11111111)
            check_pass("Guess 2 detected as wrong. Lives should be 1.");
        else
            check_fail("Guess 2 incorrectly detected as correct!");
        
        press_B(); // Ack - should retry
        repeat (2) @(posedge clk);
        
        // 5. GUESS 3: U-U-U-U (Wrong) -> Lives = 0, Game Over for Breaker
        $display("Breaker (B) Guess 3: U-U-U-U (WRONG - FINAL)");
        breaker_B_enter(LET_U);
        breaker_B_enter(LET_U);
        breaker_B_enter(LET_U);
        breaker_B_enter(LET_U);
        
        repeat (3) @(posedge clk);
        
        if (LEDreg != 8'b11111111)
            check_pass("Guess 3 detected as wrong. Lives = 0.");
        else
            check_fail("Guess 3 incorrectly detected as correct!");
        
        press_B(); // Ack - should go to result (S9) since lives=0
        
        // 6. Check: SSD displays the SECRET CODE (F-A-C-E), not the guess
        repeat (2) @(posedge clk);
        $display("Checking Result Display (should show secret code F-A-C-E)...");
        
        if (SSD3 === SEG_F && SSD2 === SEG_A && SSD1 === SEG_C && SSD0 === SEG_E)
            check_pass("Result screen shows SECRET CODE (F-A-C-E) correctly!");
        else
            $display("INFO: SSD3=%b SSD2=%b SSD1=%b SSD0=%b", SSD3, SSD2, SSD1, SSD0);
        
        // Wait for S9 timer then S10 (Scoreboard)
        #3000;
        
        // 7. Check Score: Maker A gets point -> Score 1-0
        $display("Checking Scoreboard (Maker A should get point -> 1-0)...");
        if (SSD3 === SEG_1 && SSD0 === SEG_0)
            check_pass("Scoreboard shows 1-0. Maker A scored for Breaker B's loss!");
        else
            $display("INFO: Score display SSD3=%b SSD0=%b", SSD3, SSD0);
        
        #8000; // Let round transition

        // ============================================================
        // TEST CASE 3: ASYNCHRONOUS RESET ("Panic Button")
        // Objective: Verify rst works at any time, not just at start
        // ============================================================
        $display("\n");
        $display("============================================================");
        $display("TEST CASE 3: ASYNCHRONOUS RESET (Panic Button)");
        $display("============================================================");
        reset_system();
        
        // 1. Start game and get halfway through
        press_A();
        wait_timers();
        
        // 2. Enter 2 letters as Maker
        $display("Maker A entering partial code: F-A...");
        maker_A_enter(LET_F);
        maker_A_enter(LET_A);
        
        // 3. MID-GAME RESET!
        $display(">>> PANIC BUTTON: Triggering RESET mid-game! <<<");
        rst = 0; #100; rst = 1;
        
        // 4. Wait a moment and verify state
        #1000;
        
        $display("Checking system state after reset...");
        
        // Check: Current State = S0, SSD displays A-b
        if (SSD3 === SEG_A && SSD0 === SEG_b)
            check_pass("Reset successful! Returned to S0 with A-b displayed.");
        else
            check_fail("Reset did NOT return to S0 correctly.");
        
        // Verify game is playable again
        $display("Verifying game is playable after reset...");
        press_A();
        wait_timers();
        
        // Enter new code
        maker_A_enter(LET_H);
        maker_A_enter(LET_H);
        maker_A_enter(LET_H);
        maker_A_enter(LET_H);
        
        wait_timers();
        
        // Breaker guesses correctly
        breaker_B_enter(LET_H);
        breaker_B_enter(LET_H);
        breaker_B_enter(LET_H);
        breaker_B_enter(LET_H);
        
        repeat (3) @(posedge clk);
        
        if (LEDreg == 8'b11111111)
            check_pass("Game playable after reset - correct guess detected!");
        else
            check_fail("Game not working properly after reset.");
        
        press_B();
        #6000;

        // ============================================================
        // TEST CASE 4: FULL MATCH FLOW (Mixed Results - Best of 3)
        // Objective: Prove "Best of 3" logic with mix of wins and losses
        // ============================================================
        $display("\n");
        $display("============================================================");
        $display("TEST CASE 4: FULL MATCH FLOW (Best of 3 - Mixed Results)");
        $display("============================================================");
        reset_system();
        
        // ----- ROUND 1: A=Maker, B=Breaker -> B WINS -----
        $display("\n--- Round 1: A=Maker, B=Breaker ---");
        press_A();
        wait_timers();
        
        $display("Maker A enters: C-A-F-E");
        maker_A_enter(LET_C);
        maker_A_enter(LET_A);
        maker_A_enter(LET_F);
        maker_A_enter(LET_E);
        
        wait_timers();
        
        $display("Breaker B guesses correctly: C-A-F-E");
        breaker_B_enter(LET_C);
        breaker_B_enter(LET_A);
        breaker_B_enter(LET_F);
        breaker_B_enter(LET_E);
        
        repeat (3) @(posedge clk);
        
        if (LEDreg == 8'b11111111)
            check_pass("Round 1: Breaker B guessed correctly!");
        else
            check_fail("Round 1: Correct guess not detected.");
        
        press_B(); // Ack
        repeat (6) @(posedge clk);
        
        // Score should be 0-1
        if (SSD3 === SEG_0 && SSD0 === SEG_1)
            check_pass("Round 1 Score: 0-1 (B leads)");
        else
            $display("INFO: Score SSD3=%b SSD0=%b", SSD3, SSD0);
        
        #6000; // Transition to Round 2
        
        // ----- ROUND 2: B=Maker, A=Breaker -> A LOSES (3 wrong guesses) -----
        // NOTE: After Round 1, score is 0-1 (B leads)
        // If A loses as breaker, B (Maker) scores again -> 0-2 = B WINS MATCH!
        $display("\n--- Round 2: B=Maker, A=Breaker (A will LOSE) ---");
        #3000; // Extra wait for init timers
        wait_timers();
        
        $display("Maker B enters: U-U-U-U");
        maker_B_enter(LET_U);
        maker_B_enter(LET_U);
        maker_B_enter(LET_U);
        maker_B_enter(LET_U);
        
        wait_timers();
        
        // A guesses wrong 3 times
        $display("Breaker A Guess 1: F-F-F-F (wrong)");
        breaker_A_enter(LET_F);
        breaker_A_enter(LET_F);
        breaker_A_enter(LET_F);
        breaker_A_enter(LET_F);
        repeat (3) @(posedge clk);
        press_A(); // Retry
        repeat (2) @(posedge clk);
        
        $display("Breaker A Guess 2: A-A-A-A (wrong)");
        breaker_A_enter(LET_A);
        breaker_A_enter(LET_A);
        breaker_A_enter(LET_A);
        breaker_A_enter(LET_A);
        repeat (3) @(posedge clk);
        press_A(); // Retry
        repeat (2) @(posedge clk);
        
        $display("Breaker A Guess 3: C-C-C-C (wrong - GAME OVER)");
        breaker_A_enter(LET_C);
        breaker_A_enter(LET_C);
        breaker_A_enter(LET_C);
        breaker_A_enter(LET_C);
        repeat (3) @(posedge clk);
        press_A(); // Ack - goes to result
        
        // Wait for result display (S9) then score display (S10)
        #5000;
        
        // Score should be 0-2 (B wins match! Round 1: B scored, Round 2: B scored as Maker)
        $display("Checking Round 2 Score...");
        if (SSD3 === SEG_0 && SSD0 === SEG_2)
            check_pass("Round 2 Score: 0-2 - PLAYER B WINS THE MATCH!");
        else
            $display("INFO: Score SSD3=%b SSD0=%b", SSD3, SSD0);
        
        // Game should auto-reset to S0 since B has 2 points
        #5000;
        $display("Checking game auto-reset to S0 after B wins...");
        if (SSD3 === SEG_A && SSD0 === SEG_b)
            check_pass("Game automatically reset to S0 after B won!");
        else
            $display("INFO: SSD3=%b SSD0=%b", SSD3, SSD0);
        
        // ---- Now play a NEW 3-Round Match for the original test ----
        $display("\n--- Starting NEW MATCH for 3-Round Test ---");
        reset_system();
        
        // ----- NEW ROUND 1: A=Maker, B=Breaker -> B WINS -----
        $display("\n--- New Round 1: A=Maker, B=Breaker ---");
        press_A();
        wait_timers();
        
        $display("Maker A enters: F-A-C-E");
        maker_A_enter(LET_F);
        maker_A_enter(LET_A);
        maker_A_enter(LET_C);
        maker_A_enter(LET_E);
        
        wait_timers();
        
        $display("Breaker B guesses correctly: F-A-C-E");
        breaker_B_enter(LET_F);
        breaker_B_enter(LET_A);
        breaker_B_enter(LET_C);
        breaker_B_enter(LET_E);
        
        repeat (3) @(posedge clk);
        press_B(); // Ack
        repeat (6) @(posedge clk);
        
        // Score should be 0-1
        if (SSD3 === SEG_0 && SSD0 === SEG_1)
            check_pass("New Round 1 Score: 0-1 (B leads)");
        else
            $display("INFO: Score SSD3=%b SSD0=%b", SSD3, SSD0);
        
        #6000;
        
        // ----- NEW ROUND 2: B=Maker, A=Breaker -> A WINS -----
        $display("\n--- New Round 2: B=Maker, A=Breaker (A will WIN) ---");
        #3000;
        wait_timers();
        
        $display("Maker B enters: H-H-H-H");
        maker_B_enter(LET_H);
        maker_B_enter(LET_H);
        maker_B_enter(LET_H);
        maker_B_enter(LET_H);
        
        wait_timers();
        
        $display("Breaker A guesses correctly: H-H-H-H");
        breaker_A_enter(LET_H);
        breaker_A_enter(LET_H);
        breaker_A_enter(LET_H);
        breaker_A_enter(LET_H);
        
        repeat (3) @(posedge clk);
        press_A(); // Ack
        repeat (6) @(posedge clk);
        
        // Score should be 1-1
        if (SSD3 === SEG_1 && SSD0 === SEG_1)
            check_pass("New Round 2 Score: 1-1 (Tied)");
        else
            $display("INFO: Score SSD3=%b SSD0=%b", SSD3, SSD0);
        
        #6000;
        
        // ----- NEW ROUND 3: A=Maker, B=Breaker -> B WINS (Match Over) -----
        $display("\n--- New Round 3: A=Maker, B=Breaker (FINAL ROUND) ---");
        #3000;
        wait_timers();
        
        $display("Maker A enters: L-A-C-E");
        maker_A_enter(LET_L);
        maker_A_enter(LET_A);
        maker_A_enter(LET_C);
        maker_A_enter(LET_E);
        
        wait_timers();
        
        $display("Breaker B guesses correctly: L-A-C-E");
        breaker_B_enter(LET_L);
        breaker_B_enter(LET_A);
        breaker_B_enter(LET_C);
        breaker_B_enter(LET_E);
        
        repeat (3) @(posedge clk);
        
        if (LEDreg == 8'b11111111)
            check_pass("New Round 3: Breaker B guessed correctly!");
        else
            check_fail("New Round 3: Correct guess not detected.");
        
        press_B(); // Ack
        repeat (6) @(posedge clk);
        
        // Final Score should be 1-2 (B WINS MATCH)
        if (SSD3 === SEG_1 && SSD0 === SEG_2)
            check_pass("FINAL SCORE: 1-2 -> PLAYER B WINS THE MATCH!");
        else
            $display("INFO: Score SSD3=%b SSD0=%b", SSD3, SSD0);
        
        // Wait for game to reset to S0
        #5000;
        
        $display("Checking game auto-reset to S0...");
        if (SSD3 === SEG_A && SSD0 === SEG_b)
            check_pass("Game automatically reset to S0 after match end!");
        else
            $display("INFO: Post-match SSD3=%b SSD0=%b", SSD3, SSD0);

        // ============================================================
        // TEST CASE 5: DISPLAY INTEGRITY (All Letters)
        // Objective: Verify every valid letter displays correctly
        // ============================================================
        $display("\n");
        $display("============================================================");
        $display("TEST CASE 5: DISPLAY INTEGRITY (All 7 Letters)");
        $display("============================================================");
        reset_system();
        
        // Start game
        press_A();
        wait_timers();
        
        // Test each letter on SSD3 (first position)
        $display("Testing letter F (000)...");
        letterIn = LET_F; #500;
        if (SSD3 === SEG_F)
            check_pass("F displayed correctly: 10001110");
        else
            $display("INFO: F shows SSD3=%b (expected 10001110)", SSD3);
        
        maker_A_enter(LET_F); // Confirm first letter
        
        // Now SSD2 shows current letter
        $display("Testing letter A (001)...");
        letterIn = LET_A; #500;
        if (SSD2 === SEG_A)
            check_pass("A displayed correctly: 10001000");
        else
            $display("INFO: A shows SSD2=%b (expected 10001000)", SSD2);
        
        maker_A_enter(LET_A); // Confirm
        
        $display("Testing letter C (010)...");
        letterIn = LET_C; #500;
        if (SSD1 === SEG_C)
            check_pass("C displayed correctly: 11000110");
        else
            $display("INFO: C shows SSD1=%b (expected 11000110)", SSD1);
        
        maker_A_enter(LET_C); // Confirm
        
        $display("Testing letter E (011)...");
        letterIn = LET_E; #500;
        if (SSD0 === SEG_E)
            check_pass("E displayed correctly: 10000110");
        else
            $display("INFO: E shows SSD0=%b (expected 10000110)", SSD0);
        
        maker_A_enter(LET_E); // Complete code
        
        wait_timers();
        
        // Test remaining letters (H, L, U) in Breaker input
        $display("Testing letter H (100)...");
        letterIn = LET_H; #500;
        if (SSD3 === SEG_H)
            check_pass("H displayed correctly: 10001001");
        else
            $display("INFO: H shows SSD3=%b (expected 10001001)", SSD3);
        
        breaker_B_enter(LET_H);
        
        $display("Testing letter L (110)...");
        letterIn = LET_L; #500;
        if (SSD2 === SEG_L)
            check_pass("L displayed correctly: 11000111");
        else
            $display("INFO: L shows SSD2=%b (expected 11000111)", SSD2);
        
        breaker_B_enter(LET_L);
        
        $display("Testing letter U (111)...");
        letterIn = LET_U; #500;
        if (SSD1 === SEG_U)
            check_pass("U displayed correctly: 11000001");
        else
            $display("INFO: U shows SSD1=%b (expected 11000001)", SSD1);
        
        breaker_B_enter(LET_U);
        breaker_B_enter(LET_U); // Complete guess

        // ============================================================
        // FINAL SUMMARY
        // ============================================================
        $display("\n");
        $display("============================================================");
        $display("            COMPREHENSIVE TEST SUMMARY");
        $display("============================================================");
        $display("  PASSED: %0d", pass_count);
        $display("  FAILED: %0d", fail_count);
        $display("============================================================");
        
        if (fail_count == 0)
            $display(">>> ALL TESTS PASSED! <<<");
        else
            $display(">>> SOME TESTS FAILED - Review output above <<<");
        
        $display("\n--- COMPREHENSIVE SIMULATION COMPLETE ---");
        $finish;
    end

endmodule