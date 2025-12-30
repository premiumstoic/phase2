`timescale 1ms/1ms

module tb_mastermind;

    // --- Inputs ---
    reg clk;
    reg rst;
    reg enterA;
    reg enterB;
    reg [2:0] letterIn;

    // --- Outputs ---
    wire [7:0] LEDX;
    wire [6:0] SSD3;
    wire [6:0] SSD2;
    wire [6:0] SSD1;
    wire [6:0] SSD0;

    // --- Instantiate the Device Under Test (DUT) ---
    mastermind uut (
        .clk(clk), 
        .rst(rst), 
        .enterA(enterA), 
        .enterB(enterB), 
        .letterIn(letterIn), 
        .LEDX(LEDX), 
        .SSD3(SSD3), 
        .SSD2(SSD2), 
        .SSD1(SSD1), 
        .SSD0(SSD0)
    );

    // --- Clock Generation (2 Hz) ---
    // Period = 500ms (250ms high, 250ms low)
    initial begin
        clk = 0;
        forever #250 clk = ~clk; 
    end

    // --- Helper Task: Press Button A ---
    // Simulates a button press that lasts longer than 1 clock cycle
    task press_A;
        begin
            @(negedge clk); // Sync to falling edge
            enterA = 1;
            #600;           // Hold for > 1 clock cycle (500ms)
            enterA = 0;
            #500;           // Wait for release
        end
    endtask

    // --- Helper Task: Press Button B ---
    task press_B;
        begin
            @(negedge clk);
            enterB = 1;
            #600;
            enterB = 0;
            #500;
        end
    endtask

    // --- Helper Task: Enter a Letter (Maker) ---
    task maker_enter;
        input [2:0] val;
        begin
            letterIn = val;
            #50; // Wait for switch to stabilize
            press_A();
            $display("Maker Entered Letter: %b at time %t", val, $time);
        end
    endtask

    // --- Helper Task: Enter a Letter (Breaker) ---
    task breaker_enter;
        input [2:0] val;
        begin
            letterIn = val;
            #50;
            press_B();
            $display("Breaker Entered Letter: %b at time %t", val, $time);
        end
    endtask

    // --- Main Test Sequence ---
    initial begin
        // 1. Initialize Inputs
        rst = 1;
        enterA = 0;
        enterB = 0;
        letterIn = 0;
        
        $dumpfile("mastermind_wave.vcd"); // Create waveform file for GTKWave
        $dumpvars(0, tb_mastermind);

        $display("--- SIMULATION START ---");

        // 2. Reset the System
        #100;
        rst = 0; // Active Low Reset
        #100;
        rst = 1;
        $display("System Reset.");
        #1000;

        // 3. Start Game (Press A)
        $display("State S0: Pressing Enter A to start...");
        press_A();

        // 4. Wait for Initialization (S1 & S2)
        // Each state waits 4 cycles (approx 2000ms). We wait 5000ms to be safe.
        $display("Waiting for S1 and S2 timers...");
        #5000;

        // 5. Code Maker Enters "F-A-C-E" (S3)
        // Codes: F(000), A(001), C(010), E(011)
        $display("--- Maker Inputting Code: F-A-C-E ---");
        maker_enter(3'b000); 
        maker_enter(3'b001); 
        maker_enter(3'b010); 
        maker_enter(3'b011); 

        // 6. Wait for Turn Change (S4 & S5)
        $display("Waiting for S4 and S5 timers (Player Swap)...");
        #5000;

        // 7. Code Breaker Guesses "F-A-C-E" (S6)
        $display("--- Breaker Inputting Guess: F-A-C-E ---");
        breaker_enter(3'b000); 
        breaker_enter(3'b001); 
        breaker_enter(3'b010); 
        breaker_enter(3'b011);

        // 8. Check Result (S7 -> S8)
        // S7 is instant; by two to three posedges after last input, S8 shows LEDs.
        repeat (3) @(posedge clk);

        // Check LEDs: Should be 11111111 (All correct)
        if (LEDX == 8'b11111111) 
            $display("SUCCESS: LEDs indicate Correct Guess (11111111)!");
        else 
            $display("FAILURE: LEDs show %b", LEDX);

        // Press B to acknowledge result and move to S9
        $display("Pressing B to acknowledge result...");
        press_B();

        // 9. Final Score Check (S9 -> S10)
        // After acknowledging in S8, it takes ~5 posedges to reach S10.
        repeat (6) @(posedge clk);

        // Assert scoreboard shows 0-1 in S10 (A-B)
        if (SSD3 === 7'b1111110 && SSD0 === 7'b0110000)
            $display("SUCCESS: Scoreboard shows 0-1 as expected in S10.");
        else begin
            $display("WARNING: Scoreboard unexpected in S10. SSD3=%b SSD0=%b", SSD3, SSD0);
        end
        
        $display("--- End of Round 1 ---");
        $display("Simulation Complete.");
        $finish;
    end

endmodule

// ===== EXTENDED TEST: Negative Test (Wrong Guess & Retry) =====
// Uncomment to test Round 2 with wrong guess and retry.
/*
    initial begin
    // ===== EXTENDED TEST: Negative Test (Wrong Guess & Retry) =====
    // Uncomment the block below to test a second round with a wrong guess and retry.
    initial begin
        // --- ROUND 2: Wrong Guess, then Correct Retry ---
        $display("\n=== ROUND 2: Testing Wrong Guess & Retry ===");
        
        // Wait for role swap (turn_A should now be 0 -> B is maker, A is breaker)
        repeat (6) @(posedge clk);
        
        // B (new Maker) enters code: H-A-C-E (100, 001, 010, 011)
        $display("--- Maker (B) Inputting Code: H-A-C-E ---");
        letterIn = 3'b100; press_B(); // H
        letterIn = 3'b001; press_B(); // A
        letterIn = 3'b010; press_B(); // C
        letterIn = 3'b011; press_B(); // E
        
        // Wait for S4 & S5 (player display and lives)
        repeat (10) @(posedge clk);
        
        // A (new Breaker) enters WRONG guess: F-A-C-E (should not match H at position 0)
        $display("--- Breaker (A) Entering WRONG Guess: F-A-C-E ---");
        letterIn = 3'b000; press_A(); // F (wrong, should be H)
        letterIn = 3'b001; press_A(); // A
        letterIn = 3'b010; press_A(); // C
        letterIn = 3'b011; press_A(); // E
        
        // Wait for S7 (checker) and S8 (result)
        repeat (5) @(posedge clk);
        
        // Check LEDs: Should NOT be 11111111 (F != H at position 0)
        if (LEDX !== 8'b11111111)
            $display("SUCCESS: LEDs show partial match (not all 1s). LEDX = %b", LEDX);
        else
            $display("FAILURE: LEDs show full match when they shouldn't!");
        
        // Press A to acknowledge and continue (should allow retry since lives > 0)
        $display("Pressing A to acknowledge and retry...");
        press_A();
        
        // Wait and verify lives decremented (should now be 2)
        repeat (4) @(posedge clk);
        $display("After wrong guess, lives should be 2. (Check internal state or SSD in S5 on next round.)");
        
        // A (Breaker) retries with CORRECT guess: H-A-C-E
        $display("--- Breaker (A) Retrying with CORRECT Guess: H-A-C-E ---");
        letterIn = 3'b100; press_A(); // H (correct)
        letterIn = 3'b001; press_A(); // A
        letterIn = 3'b010; press_A(); // C
        letterIn = 3'b011; press_A(); // E
        
        // Wait for S7 and S8
        repeat (5) @(posedge clk);
        
        // Check LEDs again: Should be 11111111 (all correct now)
        if (LEDX == 8'b11111111)
            $display("SUCCESS: Retry LEDs show all correct (11111111)!");
        else
            $display("FAILURE: Retry LEDs show %b", LEDX);
        
        // Press A to acknowledge result and move to S9
        press_A();
        
        // Wait and verify S9 shows secret code (H-A-C-E)
        repeat (4) @(posedge clk);
        $display("In S9, SSDs should display secret code (H-A-C-E from maker_reg).");
        
        // Move to S10 (score display)
        repeat (6) @(posedge clk);
        $display("Round 2 complete. Scoreboard shown in S10.");
        
    end
*/