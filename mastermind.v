module mastermind(
    input clk,              // 2 Hz clock for simulation 
    input rst,              // Active-low reset 
    
    input enterA,
    input enterB,
    input [2:0] letterIn,   // Switches [cite: 29]
   
    output reg [7:0] LEDX,
    output reg [6:0] SSD3,
    output reg [6:0] SSD2,
    output reg [6:0] SSD1,
    output reg [6:0] SSD0 
    );

    // --- State Encoding (Matches your ASM) ---
    localparam S0_START             = 4'd0;
    localparam S1_INIT_SCORE        = 4'd1;
    localparam S2_MAKER_DISP        = 4'd2;
    localparam S3_MAKER_INPUT       = 4'd3;
    localparam S4_BREAKER_DISP      = 4'd4;
    localparam S5_LIVES_DISP        = 4'd5;
    localparam S6_BREAKER_INPUT     = 4'd6;
    localparam S7_CHECKER           = 4'd7;
    localparam S8_UPDATE            = 4'd8;
    localparam S9_RESULT            = 4'd9;
    localparam S10_WIN_DECISION     = 4'd10;

    reg [3:0] current_state, next_state;

    // --- Game Variables ---
    reg [2:0] timer_counter;      // Counts up to 4 for 2 seconds
    reg [1:0] letter_count;       // 0 to 3 (counts inputs)
    reg [11:0] secret_code;       // Stores 4 letters (4 x 3 bits)
    reg [11:0] guess_code;        // Stores breaker's guess
    reg [1:0] score_A;
    reg [1:0] score_B;
    reg [1:0] lives;
    reg turn_A;                   // 1 if A is Code Maker, 0 if B

    // --- Internal Registers ---
    reg [2:0] maker_reg [3:0]; // Array to store the 4 letters
    reg prev_enterA;           // To remember previous state of button A
    reg prev_enterB;           // To remember previous state of button B
    reg [2:0] letter_counter;  // Counter for letters entered (0..4)

    // --- New Registers for Breaker & Checker ---
    reg [2:0] braker_reg [3:0]; // Stores the 4 guess letters
    reg [7:0] check_result;     // Stores the LED result calculated in S7

    // --- State 8 Helpers ---
    reg state_initialized;  // Ensures we only update scores/lives ONCE per turn
    wire is_correct;        // High if all 4 letters are perfect matches
    assign is_correct = (check_result[7] && check_result[6]) &&
                        (check_result[5] && check_result[4]) &&
                        (check_result[3] && check_result[2]) &&
                        (check_result[1] && check_result[0]);

    // --- Edge Detection (The "makerButtonRise" diamond) ---
    // Returns 1 only at the exact moment the button is pressed
    wire makerButtonRise;
    assign makerButtonRise = (turn_A) ? (enterA && !prev_enterA) : (enterB && !prev_enterB);

    // --- Breaker Button Edge Detection ---
    // If A is Maker (turn_A=1), B is Breaker. If B is Maker, A is Breaker.
    wire brakerButtonRise;
    assign brakerButtonRise = (turn_A) ? (enterB && !prev_enterB) : (enterA && !prev_enterA);

    // --- 7-Segment Patterns (Common Anode usually 0 is on, but check board) ---
    // Assuming standard decoding: A=0, b=1, C=2, etc. based on Table I [cite: 10]
    // 000(F), 001(A), 010(C), 011(E), 100(H), 110(L), 111(U)
    // You will need a function or separate logic to map these 3-bit codes to 7-segment
    
    // --- Sequential Logic ---
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= S0_START;
            timer_counter <= 0;
            letter_count <= 0;
            letter_counter <= 0;
            score_A <= 0;
            score_B <= 0;
            lives <= 3;
            turn_A <= 1; // Assume A starts or handled in S0
            secret_code <= 12'b0;
            prev_enterA <= 0;
            prev_enterB <= 0;
            braker_reg[0] <= 0;
            braker_reg[1] <= 0;
            braker_reg[2] <= 0;
            braker_reg[3] <= 0;
            check_result <= 8'b00000000;
            state_initialized <= 0;
        end else begin
            // 1) Update previous button states for edge detection
            prev_enterA <= enterA;
            prev_enterB <= enterB;

            // Update state
            current_state <= next_state;

            // Timer Logic (Counts 4 cycles for ~2 seconds at 2Hz)
            // Reset timer on state transitions to guarantee full dwell per state
            if (current_state != next_state) begin
                timer_counter <= 0;
            end else if (current_state == S1_INIT_SCORE || current_state == S2_MAKER_DISP || 
                         current_state == S4_BREAKER_DISP || current_state == S5_LIVES_DISP || 
                         current_state == S9_RESULT || current_state == S10_WIN_DECISION) begin
                if (timer_counter < 4)
                    timer_counter <= timer_counter + 1;
            end else begin
                timer_counter <= 0;
            end

            // 2) Logic for State 3 (Matches ASM) using makerButtonRise
            if (current_state == S3_MAKER_INPUT) begin
                if (makerButtonRise) begin
                    // Store the letter into the register array
                    maker_reg[letter_counter] <= letterIn;
                    // Increment counter
                    letter_counter <= letter_counter + 1;
                end
            end

            // --- STATE 6: Code Breaker Input ---
            else if (current_state == S6_BREAKER_INPUT) begin
                if (letter_counter == 3 && brakerButtonRise) begin
                    // Capture the last letter
                    braker_reg[3] <= letterIn;
                    // Reset counter for next time (transition decided in next-state logic)
                    letter_counter <= 0;
                end else if (brakerButtonRise) begin
                    braker_reg[letter_counter] <= letterIn;
                    letter_counter <= letter_counter + 1;
                end
            end

            // --- STATE 7: Check Logic ---
            if (current_state == S7_CHECKER) begin
                // Pair 3 (MS position)
                check_result[7] <= (braker_reg[0] == maker_reg[0]);
                check_result[6] <= (braker_reg[0] == maker_reg[0] || braker_reg[0] == maker_reg[1] ||
                                    braker_reg[0] == maker_reg[2] || braker_reg[0] == maker_reg[3]);
                // Pair 2
                check_result[5] <= (braker_reg[1] == maker_reg[1]);
                check_result[4] <= (braker_reg[1] == maker_reg[0] || braker_reg[1] == maker_reg[1] ||
                                    braker_reg[1] == maker_reg[2] || braker_reg[1] == maker_reg[3]);
                // Pair 1
                check_result[3] <= (braker_reg[2] == maker_reg[2]);
                check_result[2] <= (braker_reg[2] == maker_reg[0] || braker_reg[2] == maker_reg[1] ||
                                    braker_reg[2] == maker_reg[2] || braker_reg[2] == maker_reg[3]);
                // Pair 0 (LS position)
                check_result[1] <= (braker_reg[3] == maker_reg[3]);
                check_result[0] <= (braker_reg[3] == maker_reg[0] || braker_reg[3] == maker_reg[1] ||
                                    braker_reg[3] == maker_reg[2] || braker_reg[3] == maker_reg[3]);
            end

            // --- STATE 10: Score Display & Decision (sequential updates at expiry) ---
            if (current_state == S10_WIN_DECISION && timer_counter >= 3) begin
                if (score_A == 2 || score_B == 2) begin
                    // Match over -> reset for fresh start
                    score_A <= 0;
                    score_B <= 0;
                    lives   <= 3;
                    turn_A  <= 1;
                    letter_counter <= 0;
                end else begin
                    // Swap roles and reset round vars
                    turn_A <= ~turn_A;
                    lives   <= 3;
                    letter_counter <= 0;
                end
            end

            // --- STATE 8: Game Update & Decision (sequential side-effects) ---
            if (current_state == S8_UPDATE) begin
                // A. LOGIC PHASE (Execute only once when entering state)
                if (!state_initialized) begin
                    state_initialized <= 1; // Lock this block so it doesn't repeat

                    if (is_correct) begin
                        // Win case: increment Code Breaker's score
                        if (turn_A) score_B <= score_B + 1; // A is maker, B is breaker
                        else        score_A <= score_A + 1;
                    end else begin
                        // Wrong guess case: decrement lives
                        if (lives > 0) lives <= lives - 1;
                        // If lives was 1, it becomes 0 now -> maker scores
                        if (lives == 1) begin
                            if (turn_A) score_A <= score_A + 1;
                            else        score_B <= score_B + 1;
                        end
                    end
                end else begin
                    // B. WAIT PHASE (Wait for Breaker button)
                    if (brakerButtonRise) begin
                        state_initialized <= 0; // Reset for next time we enter S8
                        // If retrying (not correct and not out of lives), prep input counter
                        if (!is_correct && lives != 0)
                            letter_counter <= 0;
                    end
                end
            end

            // Reset counter when leaving input states so it's ready next time
            if (current_state != S3_MAKER_INPUT && current_state != S6_BREAKER_INPUT) begin
                // In ASM, initialize counter<=0 at the start; ensure it's 0 when we enter S3.
                if (current_state != S2_MAKER_DISP)
                    letter_counter <= 0;
            end
        end
    end

    // --- Next State Logic ---
    always @(*) begin
        next_state = current_state; // Default to stay
        
        case (current_state)
            S0_START: begin
                // "Initial state... As one of the players presses his enter button" [cite: 8]
                if (enterA || enterB) next_state = S1_INIT_SCORE;
            end

            S1_INIT_SCORE: begin
                // Wait 2 seconds (4 cycles) [cite: 8]
                if (timer_counter >= 3) next_state = S2_MAKER_DISP;
            end

            S2_MAKER_DISP: begin
                 // Display active player for 2 seconds [cite: 8]
                 if (timer_counter >= 3) next_state = S3_MAKER_INPUT;
            end

            S3_MAKER_INPUT: begin
                // Transition Check: "letter_counter = 4"
                if (letter_counter == 3 && makerButtonRise) begin
                    // On next clock it becomes 4; move to next state
                    next_state = S4_BREAKER_DISP;
                end
            end

            // --- STATE 4: Display Active Code Breaker ---
            S4_BREAKER_DISP: begin
                if (timer_counter >= 3)
                    next_state = S5_LIVES_DISP;
            end

            // --- STATE 5: Display Lives Left ---
            S5_LIVES_DISP: begin
                if (timer_counter >= 3)
                    next_state = S6_BREAKER_INPUT;
            end

            // --- STATE 6: Breaker Input ---
            S6_BREAKER_INPUT: begin
                if (letter_counter == 3 && brakerButtonRise)
                    next_state = S7_CHECKER;
            end

            // --- STATE 7: Checker ---
            S7_CHECKER: begin
                next_state = S8_UPDATE; // Move immediately after computing check_result
            end

            // --- STATE 8: Game Update & Decision ---
            S8_UPDATE: begin
                // Wait for Breaker button after logic has been applied
                if (state_initialized && brakerButtonRise) begin
                    if (is_correct)
                        next_state = S9_RESULT;
                    else if (lives == 0)
                        next_state = S9_RESULT;
                    else
                        next_state = S6_BREAKER_INPUT; // Retry
                end
            end

            // --- STATE 9: Result Display ---
            S9_RESULT: begin
                if (timer_counter >= 3)
                    next_state = S10_WIN_DECISION;
            end

            // --- STATE 10: Score Display & Decision ---
            S10_WIN_DECISION: begin
                if (timer_counter >= 3) begin
                    if (score_A == 2 || score_B == 2)
                        next_state = S0_START;       // Match over
                    else
                        next_state = S1_INIT_SCORE;  // Next round
                end
            end

            // ... Implement remaining transitions ...
            
            default: next_state = S0_START;
        endcase
    end

    // --- Helper: Decode 3-bit letter code to 7-segment (Combinational) ---
    reg [6:0] decoded_letterIn;
    reg [6:0] decoded_maker_0, decoded_maker_1, decoded_maker_2, decoded_maker_3;
    reg [6:0] decoded_braker_0, decoded_braker_1, decoded_braker_2, decoded_braker_3;

    always @(*) begin
        // Decode letterIn (active input)
        case (letterIn)
            3'b000: decoded_letterIn = 7'b0001110; // F
            3'b001: decoded_letterIn = 7'b0001000; // A
            3'b010: decoded_letterIn = 7'b1000110; // C
            3'b011: decoded_letterIn = 7'b0000110; // E
            3'b100: decoded_letterIn = 7'b0001001; // H
            3'b110: decoded_letterIn = 7'b1000111; // L
            3'b111: decoded_letterIn = 7'b1000001; // U
            default: decoded_letterIn = 7'b1111111; // OFF
        endcase

        // Decode maker_reg[0..3]
        case (maker_reg[0])
            3'b000: decoded_maker_0 = 7'b0001110;
            3'b001: decoded_maker_0 = 7'b0001000;
            3'b010: decoded_maker_0 = 7'b1000110;
            3'b011: decoded_maker_0 = 7'b0000110;
            3'b100: decoded_maker_0 = 7'b0001001;
            3'b110: decoded_maker_0 = 7'b1000111;
            3'b111: decoded_maker_0 = 7'b1000001;
            default: decoded_maker_0 = 7'b1111111;
        endcase

        case (maker_reg[1])
            3'b000: decoded_maker_1 = 7'b0001110;
            3'b001: decoded_maker_1 = 7'b0001000;
            3'b010: decoded_maker_1 = 7'b1000110;
            3'b011: decoded_maker_1 = 7'b0000110;
            3'b100: decoded_maker_1 = 7'b0001001;
            3'b110: decoded_maker_1 = 7'b1000111;
            3'b111: decoded_maker_1 = 7'b1000001;
            default: decoded_maker_1 = 7'b1111111;
        endcase

        case (maker_reg[2])
            3'b000: decoded_maker_2 = 7'b0001110;
            3'b001: decoded_maker_2 = 7'b0001000;
            3'b010: decoded_maker_2 = 7'b1000110;
            3'b011: decoded_maker_2 = 7'b0000110;
            3'b100: decoded_maker_2 = 7'b0001001;
            3'b110: decoded_maker_2 = 7'b1000111;
            3'b111: decoded_maker_2 = 7'b1000001;
            default: decoded_maker_2 = 7'b1111111;
        endcase

        case (maker_reg[3])
            3'b000: decoded_maker_3 = 7'b0001110;
            3'b001: decoded_maker_3 = 7'b0001000;
            3'b010: decoded_maker_3 = 7'b1000110;
            3'b011: decoded_maker_3 = 7'b0000110;
            3'b100: decoded_maker_3 = 7'b0001001;
            3'b110: decoded_maker_3 = 7'b1000111;
            3'b111: decoded_maker_3 = 7'b1000001;
            default: decoded_maker_3 = 7'b1111111;
        endcase

        // Decode braker_reg[0..3]
        case (braker_reg[0])
            3'b000: decoded_braker_0 = 7'b0001110;
            3'b001: decoded_braker_0 = 7'b0001000;
            3'b010: decoded_braker_0 = 7'b1000110;
            3'b011: decoded_braker_0 = 7'b0000110;
            3'b100: decoded_braker_0 = 7'b0001001;
            3'b110: decoded_braker_0 = 7'b1000111;
            3'b111: decoded_braker_0 = 7'b1000001;
            default: decoded_braker_0 = 7'b1111111;
        endcase

        case (braker_reg[1])
            3'b000: decoded_braker_1 = 7'b0001110;
            3'b001: decoded_braker_1 = 7'b0001000;
            3'b010: decoded_braker_1 = 7'b1000110;
            3'b011: decoded_braker_1 = 7'b0000110;
            3'b100: decoded_braker_1 = 7'b0001001;
            3'b110: decoded_braker_1 = 7'b1000111;
            3'b111: decoded_braker_1 = 7'b1000001;
            default: decoded_braker_1 = 7'b1111111;
        endcase

        case (braker_reg[2])
            3'b000: decoded_braker_2 = 7'b0001110;
            3'b001: decoded_braker_2 = 7'b0001000;
            3'b010: decoded_braker_2 = 7'b1000110;
            3'b011: decoded_braker_2 = 7'b0000110;
            3'b100: decoded_braker_2 = 7'b0001001;
            3'b110: decoded_braker_2 = 7'b1000111;
            3'b111: decoded_braker_2 = 7'b1000001;
            default: decoded_braker_2 = 7'b1111111;
        endcase

        case (braker_reg[3])
            3'b000: decoded_braker_3 = 7'b0001110;
            3'b001: decoded_braker_3 = 7'b0001000;
            3'b010: decoded_braker_3 = 7'b1000110;
            3'b011: decoded_braker_3 = 7'b0000110;
            3'b100: decoded_braker_3 = 7'b0001001;
            3'b110: decoded_braker_3 = 7'b1000111;
            3'b111: decoded_braker_3 = 7'b1000001;
            default: decoded_braker_3 = 7'b1111111;
        endcase
    end

    // --- Output Logic (SSDs) ---
    always @(*) begin
        // Default values
        SSD3 = 7'b0000000; SSD2 = 7'b0000000; SSD1 = 7'b0000000; SSD0 = 7'b0000000;
        
        case (current_state)
            S0_START: begin
                // Display "A-b" [cite: 8]
                // You need to manually define the 7-seg bits for 'A' and 'b'
                SSD3 = 7'b0001000; // Example for 'A' (active low?) - CHECK YOUR BOARD SPECS
                SSD2 = 7'b0111111; // Dash
                SSD0 = 7'b0000011; // Example for 'b'
            end
            
            // --- Display Logic for Maker Input ---
            S3_MAKER_INPUT: begin
                case (letter_counter)
                    0: begin
                        // Display current switches at first slot
                        SSD3 = decoded_letterIn;
                    end
                    1: begin
                        SSD3 = 7'b0111111; // Dash
                        SSD2 = decoded_letterIn;
                    end
                    2: begin
                        SSD3 = 7'b0111111; // Dash
                        SSD2 = 7'b0111111; // Dash
                        SSD1 = decoded_letterIn;
                    end
                    3: begin
                        SSD3 = 7'b0111111; // Dash
                        SSD2 = 7'b0111111; // Dash
                        SSD1 = 7'b0111111; // Dash
                        SSD0 = decoded_letterIn;
                    end
                    default: begin
                        // 4 or more: keep defaults (OFF)
                    end
                endcase
            end

            // --- Display active code breaker ---
            S4_BREAKER_DISP: begin
                // Display: P - [Player]
                SSD3 = 7'b1110011; // 'P'
                SSD2 = 7'b0111111; // '-'
                SSD1 = 7'b0000000; // Blank
                if (turn_A)
                    SSD0 = 7'b1111100; // 'b'
                else
                    SSD0 = 7'b1110111; // 'A'
            end

            // --- Display lives left ---
            S5_LIVES_DISP: begin
                // Display: L - [Lives]
                SSD3 = 7'b0111000; // 'L'
                SSD2 = 7'b0111111; // '-'
                SSD1 = 7'b0000000; // Blank
                case (lives)
                    2'd3: SSD0 = 7'b1001111; // '3'
                    2'd2: SSD0 = 7'b1011011; // '2'
                    2'd1: SSD0 = 7'b0000110; // '1'
                    default: SSD0 = 7'b0111111; // '-'
                endcase
            end

            // --- Display Logic for Breaker Input ---
            S6_BREAKER_INPUT: begin
                case (letter_counter)
                    0: begin
                        SSD3 = decoded_letterIn;
                        SSD2 = 7'b0000000;
                        SSD1 = 7'b0000000;
                        SSD0 = 7'b0000000;
                    end
                    1: begin
                        SSD3 = decoded_braker_0;
                        SSD2 = decoded_letterIn;
                        SSD1 = 7'b0000000;
                        SSD0 = 7'b0000000;
                    end
                    2: begin
                        SSD3 = decoded_braker_0;
                        SSD2 = decoded_braker_1;
                        SSD1 = decoded_letterIn;
                        SSD0 = 7'b0000000;
                    end
                    3: begin
                        SSD3 = decoded_braker_0;
                        SSD2 = decoded_braker_1;
                        SSD1 = decoded_braker_2;
                        SSD0 = decoded_letterIn;
                    end
                    default: begin
                    end
                endcase
            end

            // --- Display Logic for Game Update (show last guess + LEDs) ---
            S8_UPDATE: begin
                SSD3 = decoded_braker_0;
                SSD2 = decoded_braker_1;
                SSD1 = decoded_braker_2;
                SSD0 = decoded_braker_3;
            end

            // --- Display Logic for Result (show secret + LEDs) ---
            S9_RESULT: begin
                SSD3 = decoded_maker_0;
                SSD2 = decoded_maker_1;
                SSD1 = decoded_maker_2;
                SSD0 = decoded_maker_3;
            end

            // --- Display Logic for Score Decision (ScoreA - ScoreB) ---
            S10_WIN_DECISION: begin
                // Score A on SSD3
                case (score_A)
                    2'd0: SSD3 = 7'b1111110; // '0'
                    2'd1: SSD3 = 7'b0110000; // '1'
                    2'd2: SSD3 = 7'b1101101; // '2'
                    default: SSD3 = 7'b1111110;
                endcase

                SSD2 = 7'b0000001; // '-' (Dash)
                SSD1 = 7'b0000000; // Blank

                // Score B on SSD0
                case (score_B)
                    2'd0: SSD0 = 7'b1111110; // '0'
                    2'd1: SSD0 = 7'b0110000; // '1'
                    2'd2: SSD0 = 7'b1101101; // '2'
                    default: SSD0 = 7'b1111110;
                endcase
            end
            // ...
        endcase

        // LED Logic: show result in S8_UPDATE and S9_RESULT, off otherwise
        LEDX = 8'b00000000;
        if (current_state == S8_UPDATE || current_state == S9_RESULT)
            LEDX = check_result;
    end

endmodule