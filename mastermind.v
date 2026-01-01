module mastermind(
    input clk,              // 2 Hz clock for simulation
    input rst,              // Active-low reset
    
    input enterA,
    input enterB,
    input [2:0] letterIn,   // Switches
   
    output reg [7:0] LEDX,
    output reg [6:0] SSD3,
    output reg [6:0] SSD2,
    output reg [6:0] SSD1,
    output reg [6:0] SSD0 
    );

    reg [3:0] current_state; // No next_state needed for single-process
    // --- Game Variables ---
    reg [2:0] timer_counter;
    reg [1:0] letter_count;  // Used for tracking inputs (0..3)
    reg [1:0] score_A;
    reg [1:0] score_B;
    reg [1:0] lives;
    reg turn_A;              // 1 if A is Code Maker, 0 if B

    // --- Internal Registers ---
    reg [2:0] maker_reg [3:0]; // Stores the 4 secret letters
    reg [2:0] braker_reg [3:0];// Stores the 4 guess letters
    reg [7:0] check_result;    // Stores the LED result
    reg prev_enterA;           // For edge detection
    reg prev_enterB;           // For edge detection
    reg state_initialized;     // Ensures we update scores only once per state

    // --- Logic Gate Implementation for Edge Detection ---
    // We use standard gates: AND (&), OR (|), NOT (~)
    wire makerButtonRise;
    wire brakerButtonRise;

    // Logic: (TurnA AND A_Pressed AND !prev_A) OR (TurnB AND B_Pressed AND !prev_B)
    assign makerButtonRise = (turn_A & enterA & ~prev_enterA) | (~turn_A & enterB & ~prev_enterB);
    
    // Logic: (TurnA AND B_Pressed AND !prev_B) OR (TurnB AND A_Pressed AND !prev_A)
    assign brakerButtonRise = (turn_A & enterB & ~prev_enterB) | (~turn_A & enterA & ~prev_enterA);

    // --- Helper Logic: Check for Win ---
    wire is_correct;
    assign is_correct = (check_result[7] & check_result[6]) &
                        (check_result[5] & check_result[4]) &
                        (check_result[3] & check_result[2]) &
                        (check_result[1] & check_result[0]);

    // --- MAIN SINGLE PROCESS BLOCK ---
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= 4'd0; // S0_START
            timer_counter <= 0;
            letter_count <= 0;
            score_A <= 0;
            score_B <= 0;
            lives <= 3;
            turn_A <= 1; // Player A starts as Maker
            
            // Reset Arrays/Regs
            prev_enterA <= 0;
            prev_enterB <= 0;
            state_initialized <= 0;
            check_result <= 8'b0;
            maker_reg[0] <= 0; maker_reg[1] <= 0; maker_reg[2] <= 0; maker_reg[3] <= 0;
            braker_reg[0] <= 0; braker_reg[1] <= 0; braker_reg[2] <= 0; braker_reg[3] <= 0;
            
            // Clear Displays
            SSD3 <= 7'b1111111; SSD2 <= 7'b1111111; SSD1 <= 7'b1111111; SSD0 <= 7'b1111111;
            LEDX <= 8'b0;
        end 
        else begin
            // 1. Update Previous Button States
            prev_enterA <= enterA;
            prev_enterB <= enterB;

            // 2. Default LED State (Off unless specified)
            if (current_state != 4'd8 && current_state != 4'd9)
                LEDX <= 8'b00000000;

            // 3. State Machine Logic
            case (current_state)
                
                4'd0: begin
                    // Display "A-b"
                    SSD3 <= 7'b0001000; // A
                    SSD2 <= 7'b0111111; // -
                    SSD1 <= 7'b1111111; // Off
                    SSD0 <= 7'b0000011; // b
                    
                    if (enterA || enterB) 
                        current_state <= 4'd1; // S1_INIT_SCORE
                end

                4'd1: begin
                    // Display "0-0" (Initial Score)
                    SSD3 <= 7'b1000000; // 0
                    SSD2 <= 7'b0111111; // -
                    SSD1 <= 7'b1111111; // Off
                    SSD0 <= 7'b1000000; // 0
                    
                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        current_state <= 4'd2; // S2_MAKER_DISP
                    end else begin
                        timer_counter <= timer_counter + 1;
                    end
                end

                4'd2: begin
                    // Display Active Player (P-A or P-b)
                    SSD3 <= 7'b0001100; // P
                    SSD2 <= 7'b0111111; // -
                    SSD1 <= 7'b1111111;
                    if (turn_A) SSD0 <= 7'b0001000; // A
                    else        SSD0 <= 7'b0000011; // b
                    
                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        current_state <= 4'd3; // S3_MAKER_INPUT
                        letter_count <= 0; // Ensure counter is 0 before input
                    end else begin
                        timer_counter <= timer_counter + 1;
                    end
                end

                4'd3: begin
                    // Handle Display (Logic from ASM)
                    case (letter_count)
                        0: begin 
                            case (letterIn)
                                3'b000: SSD3 <= 7'b0001110; // F
                                3'b001: SSD3 <= 7'b0001000; // A
                                3'b010: SSD3 <= 7'b1000110; // C
                                3'b011: SSD3 <= 7'b0000110; // E
                                3'b100: SSD3 <= 7'b0001001; // H
                                3'b110: SSD3 <= 7'b1000111; // L
                                3'b111: SSD3 <= 7'b1000001; // U
                                default: SSD3 <= 7'b1111111; // OFF
                            endcase
                            SSD2 <= 7'b1111111; SSD1 <= 7'b1111111; SSD0 <= 7'b1111111;
                        end
                        1: begin 
                            SSD3 <= 7'b0111111; // -
                            case (letterIn)
                                3'b000: SSD2 <= 7'b0001110; // F
                                3'b001: SSD2 <= 7'b0001000; // A
                                3'b010: SSD2 <= 7'b1000110; // C
                                3'b011: SSD2 <= 7'b0000110; // E
                                3'b100: SSD2 <= 7'b0001001; // H
                                3'b110: SSD2 <= 7'b1000111; // L
                                3'b111: SSD2 <= 7'b1000001; // U
                                default: SSD2 <= 7'b1111111; // OFF
                            endcase
                            SSD1 <= 7'b1111111; SSD0 <= 7'b1111111;
                        end
                        2: begin 
                            SSD3 <= 7'b0111111; SSD2 <= 7'b0111111;
                            case (letterIn)
                                3'b000: SSD1 <= 7'b0001110; // F
                                3'b001: SSD1 <= 7'b0001000; // A
                                3'b010: SSD1 <= 7'b1000110; // C
                                3'b011: SSD1 <= 7'b0000110; // E
                                3'b100: SSD1 <= 7'b0001001; // H
                                3'b110: SSD1 <= 7'b1000111; // L
                                3'b111: SSD1 <= 7'b1000001; // U
                                default: SSD1 <= 7'b1111111; // OFF
                            endcase
                            SSD0 <= 7'b1111111;
                        end
                        3: begin 
                            SSD3 <= 7'b0111111; SSD2 <= 7'b0111111; SSD1 <= 7'b0111111;
                            case (letterIn)
                                3'b000: SSD0 <= 7'b0001110; // F
                                3'b001: SSD0 <= 7'b0001000; // A
                                3'b010: SSD0 <= 7'b1000110; // C
                                3'b011: SSD0 <= 7'b0000110; // E
                                3'b100: SSD0 <= 7'b0001001; // H
                                3'b110: SSD0 <= 7'b1000111; // L
                                3'b111: SSD0 <= 7'b1000001; // U
                                default: SSD0 <= 7'b1111111; // OFF
                            endcase
                        end
                    endcase

                    // Handle Input
                    if (makerButtonRise) begin
                        maker_reg[letter_count] <= letterIn;
                        if (letter_count == 3) begin
                            current_state <= 4'd4; // S4_BREAKER_DISP
                            letter_count <= 0; // Reset for next usage
                        end else begin
                            letter_count <= letter_count + 1;
                        end
                    end
                end

                4'd4: begin
                    // Display Breaker (Opposite of Turn A)
                    SSD3 <= 7'b0001100; // P
                    SSD2 <= 7'b0111111; // -
                    SSD1 <= 7'b1111111;
                    if (turn_A) SSD0 <= 7'b0000011; // b (Breaker is B)
                    else        SSD0 <= 7'b0001000; // A
                    
                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        current_state <= 4'd5; // S5_LIVES_DISP
                    end else begin
                        timer_counter <= timer_counter + 1;
                    end
                end

                4'd5: begin
                    // Display Lives (L-3)
                    SSD3 <= 7'b1000111; // L
                    SSD2 <= 7'b0111111; // -
                    SSD1 <= 7'b1111111;
                    // Simple decode for 1, 2, 3
                    case(lives)
                        2'd3: SSD0 <= 7'b0110000; // 3
                        2'd2: SSD0 <= 7'b1101101; // 2
                        2'd1: SSD0 <= 7'b0110000; // 1
                        default: SSD0 <= 7'b0111111; // -
                    endcase

                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        current_state <= 4'd6; // S6_BREAKER_INPUT
                        letter_count <= 0;
                    end else begin
                        timer_counter <= timer_counter + 1;
                    end
                end

                4'd6: begin
                    // Handle Display (Accumulate letters)
                    case (letter_count)
                        0: begin 
                            case (letterIn)
                                3'b000: SSD3 <= 7'b0001110; // F
                                3'b001: SSD3 <= 7'b0001000; // A
                                3'b010: SSD3 <= 7'b1000110; // C
                                3'b011: SSD3 <= 7'b0000110; // E
                                3'b100: SSD3 <= 7'b0001001; // H
                                3'b110: SSD3 <= 7'b1000111; // L
                                3'b111: SSD3 <= 7'b1000001; // U
                                default: SSD3 <= 7'b1111111; // OFF
                            endcase
                            SSD2 <= 7'b1111111; SSD1 <= 7'b1111111; SSD0 <= 7'b1111111;
                        end
                        1: begin 
                            case (braker_reg[0])
                                3'b000: SSD3 <= 7'b0001110; // F
                                3'b001: SSD3 <= 7'b0001000; // A
                                3'b010: SSD3 <= 7'b1000110; // C
                                3'b011: SSD3 <= 7'b0000110; // E
                                3'b100: SSD3 <= 7'b0001001; // H
                                3'b110: SSD3 <= 7'b1000111; // L
                                3'b111: SSD3 <= 7'b1000001; // U
                                default: SSD3 <= 7'b1111111; // OFF
                            endcase
                            case (letterIn)
                                3'b000: SSD2 <= 7'b0001110; // F
                                3'b001: SSD2 <= 7'b0001000; // A
                                3'b010: SSD2 <= 7'b1000110; // C
                                3'b011: SSD2 <= 7'b0000110; // E
                                3'b100: SSD2 <= 7'b0001001; // H
                                3'b110: SSD2 <= 7'b1000111; // L
                                3'b111: SSD2 <= 7'b1000001; // U
                                default: SSD2 <= 7'b1111111; // OFF
                            endcase
                            SSD1 <= 7'b1111111; SSD0 <= 7'b1111111;
                        end
                        2: begin 
                            case (braker_reg[0])
                                3'b000: SSD3 <= 7'b0001110; // F
                                3'b001: SSD3 <= 7'b0001000; // A
                                3'b010: SSD3 <= 7'b1000110; // C
                                3'b011: SSD3 <= 7'b0000110; // E
                                3'b100: SSD3 <= 7'b0001001; // H
                                3'b110: SSD3 <= 7'b1000111; // L
                                3'b111: SSD3 <= 7'b1000001; // U
                                default: SSD3 <= 7'b1111111; // OFF
                            endcase
                            case (braker_reg[1])
                                3'b000: SSD2 <= 7'b0001110; // F
                                3'b001: SSD2 <= 7'b0001000; // A
                                3'b010: SSD2 <= 7'b1000110; // C
                                3'b011: SSD2 <= 7'b0000110; // E
                                3'b100: SSD2 <= 7'b0001001; // H
                                3'b110: SSD2 <= 7'b1000111; // L
                                3'b111: SSD2 <= 7'b1000001; // U
                                default: SSD2 <= 7'b1111111; // OFF
                            endcase
                            case (letterIn)
                                3'b000: SSD1 <= 7'b0001110; // F
                                3'b001: SSD1 <= 7'b0001000; // A
                                3'b010: SSD1 <= 7'b1000110; // C
                                3'b011: SSD1 <= 7'b0000110; // E
                                3'b100: SSD1 <= 7'b0001001; // H
                                3'b110: SSD1 <= 7'b1000111; // L
                                3'b111: SSD1 <= 7'b1000001; // U
                                default: SSD1 <= 7'b1111111; // OFF
                            endcase
                            SSD0 <= 7'b1111111;
                        end
                        3: begin 
                            case (braker_reg[0])
                                3'b000: SSD3 <= 7'b0001110; // F
                                3'b001: SSD3 <= 7'b0001000; // A
                                3'b010: SSD3 <= 7'b1000110; // C
                                3'b011: SSD3 <= 7'b0000110; // E
                                3'b100: SSD3 <= 7'b0001001; // H
                                3'b110: SSD3 <= 7'b1000111; // L
                                3'b111: SSD3 <= 7'b1000001; // U
                                default: SSD3 <= 7'b1111111; // OFF
                            endcase
                            case (braker_reg[1])
                                3'b000: SSD2 <= 7'b0001110; // F
                                3'b001: SSD2 <= 7'b0001000; // A
                                3'b010: SSD2 <= 7'b1000110; // C
                                3'b011: SSD2 <= 7'b0000110; // E
                                3'b100: SSD2 <= 7'b0001001; // H
                                3'b110: SSD2 <= 7'b1000111; // L
                                3'b111: SSD2 <= 7'b1000001; // U
                                default: SSD2 <= 7'b1111111; // OFF
                            endcase
                            case (braker_reg[2])
                                3'b000: SSD1 <= 7'b0001110; // F
                                3'b001: SSD1 <= 7'b0001000; // A
                                3'b010: SSD1 <= 7'b1000110; // C
                                3'b011: SSD1 <= 7'b0000110; // E
                                3'b100: SSD1 <= 7'b0001001; // H
                                3'b110: SSD1 <= 7'b1000111; // L
                                3'b111: SSD1 <= 7'b1000001; // U
                                default: SSD1 <= 7'b1111111; // OFF
                            endcase
                            case (letterIn)
                                3'b000: SSD0 <= 7'b0001110; // F
                                3'b001: SSD0 <= 7'b0001000; // A
                                3'b010: SSD0 <= 7'b1000110; // C
                                3'b011: SSD0 <= 7'b0000110; // E
                                3'b100: SSD0 <= 7'b0001001; // H
                                3'b110: SSD0 <= 7'b1000111; // L
                                3'b111: SSD0 <= 7'b1000001; // U
                                default: SSD0 <= 7'b1111111; // OFF
                            endcase
                        end
                    endcase

                    // Handle Input
                    if (brakerButtonRise) begin
                        braker_reg[letter_count] <= letterIn;
                        if (letter_count == 3) begin
                            current_state <= 4'd7; // S7_CHECKER
                            letter_count <= 0;
                        end else begin
                            letter_count <= letter_count + 1;
                        end
                    end
                end

                4'd7: begin
                    // Calculate LEDs (One shot state)
                    // Pair 3
                    check_result[7] <= (braker_reg[0] == maker_reg[0]); 
                    check_result[6] <= (braker_reg[0] == maker_reg[0] | braker_reg[0] == maker_reg[1] | 
                                        braker_reg[0] == maker_reg[2] | braker_reg[0] == maker_reg[3]);
                    // Pair 2
                    check_result[5] <= (braker_reg[1] == maker_reg[1]); 
                    check_result[4] <= (braker_reg[1] == maker_reg[0] | braker_reg[1] == maker_reg[1] | 
                                        braker_reg[1] == maker_reg[2] | braker_reg[1] == maker_reg[3]);
                    // Pair 1
                    check_result[3] <= (braker_reg[2] == maker_reg[2]); 
                    check_result[2] <= (braker_reg[2] == maker_reg[0] | braker_reg[2] == maker_reg[1] | 
                                        braker_reg[2] == maker_reg[2] | braker_reg[2] == maker_reg[3]);
                    // Pair 0
                    check_result[1] <= (braker_reg[3] == maker_reg[3]); 
                    check_result[0] <= (braker_reg[3] == maker_reg[0] | braker_reg[3] == maker_reg[1] | 
                                        braker_reg[3] == maker_reg[2] | braker_reg[3] == maker_reg[3]);
                    
                    current_state <= 4'd8; // S8_UPDATE
                end

                4'd8: begin
                    // Display Last Guess & LEDs
                    case (braker_reg[0])
                        3'b000: SSD3 <= 7'b0001110; // F
                        3'b001: SSD3 <= 7'b0001000; // A
                        3'b010: SSD3 <= 7'b1000110; // C
                        3'b011: SSD3 <= 7'b0000110; // E
                        3'b100: SSD3 <= 7'b0001001; // H
                        3'b110: SSD3 <= 7'b1000111; // L
                        3'b111: SSD3 <= 7'b1000001; // U
                        default: SSD3 <= 7'b1111111; // OFF
                    endcase
                    case (braker_reg[1])
                        3'b000: SSD2 <= 7'b0001110; // F
                        3'b001: SSD2 <= 7'b0001000; // A
                        3'b010: SSD2 <= 7'b1000110; // C
                        3'b011: SSD2 <= 7'b0000110; // E
                        3'b100: SSD2 <= 7'b0001001; // H
                        3'b110: SSD2 <= 7'b1000111; // L
                        3'b111: SSD2 <= 7'b1000001; // U
                        default: SSD2 <= 7'b1111111; // OFF
                    endcase
                    case (braker_reg[2])
                        3'b000: SSD1 <= 7'b0001110; // F
                        3'b001: SSD1 <= 7'b0001000; // A
                        3'b010: SSD1 <= 7'b1000110; // C
                        3'b011: SSD1 <= 7'b0000110; // E
                        3'b100: SSD1 <= 7'b0001001; // H
                        3'b110: SSD1 <= 7'b1000111; // L
                        3'b111: SSD1 <= 7'b1000001; // U
                        default: SSD1 <= 7'b1111111; // OFF
                    endcase
                    case (braker_reg[3])
                        3'b000: SSD0 <= 7'b0001110; // F
                        3'b001: SSD0 <= 7'b0001000; // A
                        3'b010: SSD0 <= 7'b1000110; // C
                        3'b011: SSD0 <= 7'b0000110; // E
                        3'b100: SSD0 <= 7'b0001001; // H
                        3'b110: SSD0 <= 7'b1000111; // L
                        3'b111: SSD0 <= 7'b1000001; // U
                        default: SSD0 <= 7'b1111111; // OFF
                    endcase
                    LEDX <= check_result;

                    if (!state_initialized) begin
                        state_initialized <= 1;
                        if (is_correct) begin
                            if (turn_A) score_B <= score_B + 1;
                            else        score_A <= score_A + 1;
                        end else begin
                            if (lives > 0) lives <= lives - 1;
                            if (lives == 1) begin // Will be 0 next
                                if (turn_A) score_A <= score_A + 1;
                                else        score_B <= score_B + 1;
                            end
                        end
                    end 
                    else begin
                        if (brakerButtonRise) begin
                            state_initialized <= 0;
                            if (is_correct || lives == 0)
                                current_state <= 4'd9; // S9_RESULT
                            else begin
                                current_state <= 4'd6; // S6_BREAKER_INPUT
                                letter_count <= 0;
                            end
                        end
                    end
                end

                4'd9: begin
                    // Display Secret Code & LEDs
                    case (maker_reg[0])
                        3'b000: SSD3 <= 7'b0001110; // F
                        3'b001: SSD3 <= 7'b0001000; // A
                        3'b010: SSD3 <= 7'b1000110; // C
                        3'b011: SSD3 <= 7'b0000110; // E
                        3'b100: SSD3 <= 7'b0001001; // H
                        3'b110: SSD3 <= 7'b1000111; // L
                        3'b111: SSD3 <= 7'b1000001; // U
                        default: SSD3 <= 7'b1111111; // OFF
                    endcase
                    case (maker_reg[1])
                        3'b000: SSD2 <= 7'b0001110; // F
                        3'b001: SSD2 <= 7'b0001000; // A
                        3'b010: SSD2 <= 7'b1000110; // C
                        3'b011: SSD2 <= 7'b0000110; // E
                        3'b100: SSD2 <= 7'b0001001; // H
                        3'b110: SSD2 <= 7'b1000111; // L
                        3'b111: SSD2 <= 7'b1000001; // U
                        default: SSD2 <= 7'b1111111; // OFF
                    endcase
                    case (maker_reg[2])
                        3'b000: SSD1 <= 7'b0001110; // F
                        3'b001: SSD1 <= 7'b0001000; // A
                        3'b010: SSD1 <= 7'b1000110; // C
                        3'b011: SSD1 <= 7'b0000110; // E
                        3'b100: SSD1 <= 7'b0001001; // H
                        3'b110: SSD1 <= 7'b1000111; // L
                        3'b111: SSD1 <= 7'b1000001; // U
                        default: SSD1 <= 7'b1111111; // OFF
                    endcase
                    case (maker_reg[3])
                        3'b000: SSD0 <= 7'b0001110; // F
                        3'b001: SSD0 <= 7'b0001000; // A
                        3'b010: SSD0 <= 7'b1000110; // C
                        3'b011: SSD0 <= 7'b0000110; // E
                        3'b100: SSD0 <= 7'b0001001; // H
                        3'b110: SSD0 <= 7'b1000111; // L
                        3'b111: SSD0 <= 7'b1000001; // U
                        default: SSD0 <= 7'b1111111; // OFF
                    endcase
                    LEDX <= check_result;

                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        current_state <= 4'd10; // S10_WIN_DECISION
                    end else begin
                        timer_counter <= timer_counter + 1;
                    end
                end

                4'd10: begin
                    // Display Scores (ScoreA - ScoreB)
                    case(score_A)
                        2'd0: SSD3 <= 7'b1000000; // 0
                        2'd1: SSD3 <= 7'b1111001; // 1
                        2'd2: SSD3 <= 7'b0100100; // 2
                        default: SSD3 <= 7'b1000000;
                    endcase
                    SSD2 <= 7'b0111111; // -
                    SSD1 <= 7'b1111111; // Off
                    case(score_B)
                        2'd0: SSD0 <= 7'b1000000; // 0
                        2'd1: SSD0 <= 7'b1111001; // 1
                        2'd2: SSD0 <= 7'b0100100; // 2
                        default: SSD0 <= 7'b1000000;
                    endcase

                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        if (score_A == 2 || score_B == 2) begin
                            current_state <= 4'd0; // Game Over
                            score_A <= 0; score_B <= 0; lives <= 3; turn_A <= 1;
                        end else begin
                            current_state <= 4'd1; // Next Round
                            turn_A <= ~turn_A; // Swap roles
                            lives <= 3;
                        end
                    end else begin
                        timer_counter <= timer_counter + 1;
                    end
                end
                
                default: current_state <= 4'd0; // Safety Reset
            endcase
        end
    end
endmodule
