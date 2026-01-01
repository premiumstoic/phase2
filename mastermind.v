module mastermind(
    input clk,              // 2 Hz clock for simulation
    input rst,              // Active-low reset
    
    input enterA,
    input enterB,
    input [2:0] letterIn,
   
    output reg [7:0] LEDX,
    output reg [7:0] SSD3,
    output reg [7:0] SSD2,
    output reg [7:0] SSD1,
    output reg [7:0] SSD0   
    );

    reg [3:0] current_state;
    reg [2:0] timer_counter;
    reg [1:0] letter_count;
    reg [1:0] score_A;
    reg [1:0] score_B;
    reg [1:0] lives;
    reg turn_A;

    reg [2:0] maker_reg [3:0];
    reg [2:0] braker_reg [3:0];
    reg [7:0] check_result;
    reg prev_enterA;
    reg prev_enterB;

    wire makerButtonRise;
    wire brakerButtonRise;

    assign makerButtonRise = (turn_A & enterA & ~prev_enterA) | (~turn_A & enterB & ~prev_enterB);
    assign brakerButtonRise = (turn_A & enterB & ~prev_enterB) | (~turn_A & enterA & ~prev_enterA);

    // --- Helper Logic: Check for Win ---
    wire is_correct;
    assign is_correct = (check_result[7] & check_result[6]) & (check_result[5] & check_result[4]) &
                        (check_result[3] & check_result[2]) & (check_result[1] & check_result[0]);

    // --- MAIN SINGLE PROCESS BLOCK ---
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= 4'd0;
            timer_counter <= 0;
            letter_count <= 0;
            score_A <= 0;
            score_B <= 0;
            lives <= 3;
            turn_A <= 1;
            
            prev_enterA <= 0;
            prev_enterB <= 0;
            check_result <= 8'b0;
            
            maker_reg[0] <= 0; maker_reg[1] <= 0; maker_reg[2] <= 0; maker_reg[3] <= 0;
            braker_reg[0] <= 0; braker_reg[1] <= 0; braker_reg[2] <= 0; braker_reg[3] <= 0;
            
            SSD3 <= 8'b11111111; SSD2 <= 8'b11111111; SSD1 <= 8'b11111111; SSD0 <= 8'b11111111;
            LEDX <= 8'b0;
        end 
        else begin
            prev_enterA <= enterA;
            prev_enterB <= enterB;

            if (current_state != 4'd8 && current_state != 4'd9 && current_state != 4'd11) begin
                LEDX <= 8'b00000000;
            end

            case (current_state)
                
                4'd0: begin
                    SSD3 <= 8'b10001000; // A
                    SSD2 <= 8'b10111111; // -
                    SSD1 <= 8'b11111111; // Off
                    SSD0 <= 8'b10000011; // b
                    
                    if (enterA || enterB) begin
                        current_state <= 4'd1;
                    end
                end

                4'd1: begin
                    SSD3 <= 8'b11000000; // 0
                    SSD2 <= 8'b10111111; // -
                    SSD1 <= 8'b11111111; // Off
                    SSD0 <= 8'b11000000; // 0
                    
                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        current_state <= 4'd2;
                    end 
                    else begin
                        timer_counter <= timer_counter + 1;
                    end
                end

                4'd2: begin
                    SSD3 <= 8'b10001100; // P
                    SSD2 <= 8'b10111111; // -
                    SSD1 <= 8'b11111111;
                    if (turn_A) begin
                        SSD0 <= 8'b10001000; // A
                    end
                    else begin
                        SSD0 <= 8'b10000011; // b
                    end
                    
                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        current_state <= 4'd3;
                        letter_count <= 0;
                    end
                    else begin
                        timer_counter <= timer_counter + 1;
                    end
                end

                4'd3: begin
                    case (letter_count)
                        0: begin 
                            case (letterIn)
                                3'b000: SSD3 <= 8'b10001110; // F
                                3'b001: SSD3 <= 8'b10001000; // A
                                3'b010: SSD3 <= 8'b11000110; // C
                                3'b011: SSD3 <= 8'b10000110; // E
                                3'b100: SSD3 <= 8'b10001001; // H
                                3'b110: SSD3 <= 8'b11000111; // L
                                3'b111: SSD3 <= 8'b11000001; // U
                                default: SSD3 <= 8'b11111111; // OFF
                            endcase
                            SSD2 <= 8'b11111111; SSD1 <= 8'b11111111; SSD0 <= 8'b11111111;
                        end
                        1: begin 
                            SSD3 <= 8'b10111111; // -
                            case (letterIn)
                                3'b000: SSD2 <= 8'b10001110; // F
                                3'b001: SSD2 <= 8'b10001000; // A
                                3'b010: SSD2 <= 8'b11000110; // C
                                3'b011: SSD2 <= 8'b10000110; // E
                                3'b100: SSD2 <= 8'b10001001; // H
                                3'b110: SSD2 <= 8'b11000111; // L
                                3'b111: SSD2 <= 8'b11000001; // U
                                default: SSD2 <= 8'b11111111; // OFF
                            endcase
                            SSD1 <= 8'b11111111; SSD0 <= 8'b11111111;
                        end
                        2: begin 
                            SSD3 <= 8'b10111111; SSD2 <= 8'b10111111;
                            case (letterIn)
                                3'b000: SSD1 <= 8'b10001110; // F
                                3'b001: SSD1 <= 8'b10001000; // A
                                3'b010: SSD1 <= 8'b11000110; // C
                                3'b011: SSD1 <= 8'b10000110; // E
                                3'b100: SSD1 <= 8'b10001001; // H
                                3'b110: SSD1 <= 8'b11000111; // L
                                3'b111: SSD1 <= 8'b11000001; // U
                                default: SSD1 <= 8'b11111111; // OFF
                            endcase
                            SSD0 <= 8'b11111111;
                        end
                        3: begin 
                            SSD3 <= 8'b10111111; SSD2 <= 8'b10111111; SSD1 <= 8'b10111111;
                            case (letterIn)
                                3'b000: SSD0 <= 8'b10001110; // F
                                3'b001: SSD0 <= 8'b10001000; // A
                                3'b010: SSD0 <= 8'b11000110; // C
                                3'b011: SSD0 <= 8'b10000110; // E
                                3'b100: SSD0 <= 8'b10001001; // H
                                3'b110: SSD0 <= 8'b11000111; // L
                                3'b111: SSD0 <= 8'b11000001; // U
                                default: SSD0 <= 8'b11111111; // OFF
                            endcase
                        end
                    endcase

                    if (makerButtonRise) begin
                        maker_reg[letter_count] <= letterIn;
                        if (letter_count == 3) begin
                            current_state <= 4'd4;
                            letter_count <= 0;
                        end
                        else begin
                            letter_count <= letter_count + 1;
                        end
                    end
                end

                4'd4: begin
                    SSD3 <= 8'b10001100; // P
                    SSD2 <= 8'b10111111; // -
                    SSD1 <= 8'b11111111;
                    if (turn_A) begin
                        SSD0 <= 8'b10000011; // b
                    end 
                    else begin
                        SSD0 <= 8'b10001000; // A
                    end
                    
                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        current_state <= 4'd5;
                    end 
                    else begin
                        timer_counter <= timer_counter + 1;
                    end
                end

                4'd5: begin
                    SSD3 <= 8'b10001111; // L
                    SSD2 <= 8'b10111111; // -
                    SSD1 <= 8'b11111111;
                    case(lives)
                        2'd3: SSD0 <= 8'b10110000; // 3
                        2'd2: SSD0 <= 8'b10100100; // 2
                        2'd1: SSD0 <= 8'b11111001; // 1
                        default: SSD0 <= 8'b10111111; // -
                    endcase

                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        current_state <= 4'd6;
                        letter_count <= 0;
                    end 
                    else begin
                        timer_counter <= timer_counter + 1;
                    end
                end

                4'd6: begin
                    case (letter_count)
                        0: begin 
                            case (letterIn)
                                3'b000: SSD3 <= 8'b10001110; // F
                                3'b001: SSD3 <= 8'b10001000; // A
                                3'b010: SSD3 <= 8'b11000110; // C
                                3'b011: SSD3 <= 8'b10000110; // E
                                3'b100: SSD3 <= 8'b10001001; // H
                                3'b110: SSD3 <= 8'b11000111; // L
                                3'b111: SSD3 <= 8'b11000001; // U
                                default: SSD3 <= 8'b11111111; // OFF
                            endcase
                            SSD2 <= 8'b11111111; SSD1 <= 8'b11111111; SSD0 <= 8'b11111111;
                        end
                        1: begin 
                            case (braker_reg[0])
                                3'b000: SSD3 <= 8'b10001110; // F
                                3'b001: SSD3 <= 8'b10001000; // A
                                3'b010: SSD3 <= 8'b11000110; // C
                                3'b011: SSD3 <= 8'b10000110; // E
                                3'b100: SSD3 <= 8'b10001001; // H
                                3'b110: SSD3 <= 8'b11000111; // L
                                3'b111: SSD3 <= 8'b11000001; // U
                                default: SSD3 <= 8'b11111111; // OFF
                            endcase
                            case (letterIn)
                                3'b000: SSD2 <= 8'b10001110; // F
                                3'b001: SSD2 <= 8'b10001000; // A
                                3'b010: SSD2 <= 8'b11000110; // C
                                3'b011: SSD2 <= 8'b10000110; // E
                                3'b100: SSD2 <= 8'b10001001; // H
                                3'b110: SSD2 <= 8'b11000111; // L
                                3'b111: SSD2 <= 8'b11000001; // U
                                default: SSD2 <= 8'b11111111; // OFF
                            endcase
                            SSD1 <= 8'b11111111; SSD0 <= 8'b11111111;
                        end
                        2: begin 
                            case (braker_reg[0])
                                3'b000: SSD3 <= 8'b10001110; // F
                                3'b001: SSD3 <= 8'b10001000; // A
                                3'b010: SSD3 <= 8'b11000110; // C
                                3'b011: SSD3 <= 8'b10000110; // E
                                3'b100: SSD3 <= 8'b10001001; // H
                                3'b110: SSD3 <= 8'b11000111; // L
                                3'b111: SSD3 <= 8'b11000001; // U
                                default: SSD3 <= 8'b11111111; // OFF
                            endcase
                            case (braker_reg[1])
                                3'b000: SSD2 <= 8'b10001110; // F
                                3'b001: SSD2 <= 8'b10001000; // A
                                3'b010: SSD2 <= 8'b11000110; // C
                                3'b011: SSD2 <= 8'b10000110; // E
                                3'b100: SSD2 <= 8'b10001001; // H
                                3'b110: SSD2 <= 8'b11000111; // L
                                3'b111: SSD2 <= 8'b11000001; // U
                                default: SSD2 <= 8'b11111111; // OFF
                            endcase
                            case (letterIn)
                                3'b000: SSD1 <= 8'b10001110; // F
                                3'b001: SSD1 <= 8'b10001000; // A
                                3'b010: SSD1 <= 8'b11000110; // C
                                3'b011: SSD1 <= 8'b10000110; // E
                                3'b100: SSD1 <= 8'b10001001; // H
                                3'b110: SSD1 <= 8'b11000111; // L
                                3'b111: SSD1 <= 8'b11000001; // U
                                default: SSD1 <= 8'b11111111; // OFF
                            endcase
                            SSD0 <= 8'b11111111;
                        end
                        3: begin 
                            case (braker_reg[0])
                                3'b000: SSD3 <= 8'b10001110; // F
                                3'b001: SSD3 <= 8'b10001000; // A
                                3'b010: SSD3 <= 8'b11000110; // C
                                3'b011: SSD3 <= 8'b10000110; // E
                                3'b100: SSD3 <= 8'b10001001; // H
                                3'b110: SSD3 <= 8'b11000111; // L
                                3'b111: SSD3 <= 8'b11000001; // U
                                default: SSD3 <= 8'b11111111; // OFF
                            endcase
                            case (braker_reg[1])
                                3'b000: SSD2 <= 8'b10001110; // F
                                3'b001: SSD2 <= 8'b10001000; // A
                                3'b010: SSD2 <= 8'b11000110; // C
                                3'b011: SSD2 <= 8'b10000110; // E
                                3'b100: SSD2 <= 8'b10001001; // H
                                3'b110: SSD2 <= 8'b11000111; // L
                                3'b111: SSD2 <= 8'b11000001; // U
                                default: SSD2 <= 8'b11111111; // OFF
                            endcase
                            case (braker_reg[2])
                                3'b000: SSD1 <= 8'b10001110; // F
                                3'b001: SSD1 <= 8'b10001000; // A
                                3'b010: SSD1 <= 8'b11000110; // C
                                3'b011: SSD1 <= 8'b10000110; // E
                                3'b100: SSD1 <= 8'b10001001; // H
                                3'b110: SSD1 <= 8'b11000111; // L
                                3'b111: SSD1 <= 8'b11000001; // U
                                default: SSD1 <= 8'b11111111; // OFF
                            endcase
                            case (letterIn)
                                3'b000: SSD0 <= 8'b10001110; // F
                                3'b001: SSD0 <= 8'b10001000; // A
                                3'b010: SSD0 <= 8'b11000110; // C
                                3'b011: SSD0 <= 8'b10000110; // E
                                3'b100: SSD0 <= 8'b10001001; // H
                                3'b110: SSD0 <= 8'b11000111; // L
                                3'b111: SSD0 <= 8'b11000001; // U
                                default: SSD0 <= 8'b11111111; // OFF
                            endcase
                        end
                    endcase

                    if (brakerButtonRise) begin
                        braker_reg[letter_count] <= letterIn;
                        if (letter_count == 3) begin
                            current_state <= 4'd7;
                            letter_count <= 0;
                        end 
                        else begin
                            letter_count <= letter_count + 1;
                        end
                    end
                end

                4'd7: begin
                    check_result[7] <= (braker_reg[0] == maker_reg[0]); 
                    check_result[6] <= (braker_reg[0] == maker_reg[0] | braker_reg[0] == maker_reg[1] | 
                                        braker_reg[0] == maker_reg[2] | braker_reg[0] == maker_reg[3]);
                    check_result[5] <= (braker_reg[1] == maker_reg[1]); 
                    check_result[4] <= (braker_reg[1] == maker_reg[0] | braker_reg[1] == maker_reg[1] | 
                                        braker_reg[1] == maker_reg[2] | braker_reg[1] == maker_reg[3]);
                    check_result[3] <= (braker_reg[2] == maker_reg[2]); 
                    check_result[2] <= (braker_reg[2] == maker_reg[0] | braker_reg[2] == maker_reg[1] | 
                                        braker_reg[2] == maker_reg[2] | braker_reg[2] == maker_reg[3]);
                    check_result[1] <= (braker_reg[3] == maker_reg[3]); 
                    check_result[0] <= (braker_reg[3] == maker_reg[0] | braker_reg[3] == maker_reg[1] | 
                                        braker_reg[3] == maker_reg[2] | braker_reg[3] == maker_reg[3]);
                    current_state <= 4'd8;
                end

                4'd8: begin
                    // --- STATE 8: CALCULATION (One-Shot) ---
                    // Perform calculations immediately
                    if (is_correct) begin
                        if (turn_A) begin
                            score_B <= score_B + 1;
                        end
                        else begin
                            score_A <= score_A + 1;
                        end
                    end 
                    else begin
                        if (lives > 0) begin
                            lives <= lives - 1;
                        end
                    end
                    
                    // Display guess immediately
                    case (braker_reg[0])
                        3'b000: SSD3 <= 8'b10001110; // F
                        3'b001: SSD3 <= 8'b10001000; // A
                        3'b010: SSD3 <= 8'b11000110; // C
                        3'b011: SSD3 <= 8'b10000110; // E
                        3'b100: SSD3 <= 8'b10001001; // H
                        3'b110: SSD3 <= 8'b11000111; // L
                        3'b111: SSD3 <= 8'b11000001; // U
                        default: SSD3 <= 8'b11111111; // OFF
                    endcase
                    case (braker_reg[1])
                        3'b000: SSD2 <= 8'b10001110; // F
                        3'b001: SSD2 <= 8'b10001000; // A
                        3'b010: SSD2 <= 8'b11000110; // C
                        3'b011: SSD2 <= 8'b10000110; // E
                        3'b100: SSD2 <= 8'b10001001; // H
                        3'b110: SSD2 <= 8'b11000111; // L
                        3'b111: SSD2 <= 8'b11000001; // U
                        default: SSD2 <= 8'b11111111; // OFF
                    endcase
                    case (braker_reg[2])
                        3'b000: SSD1 <= 8'b10001110; // F
                        3'b001: SSD1 <= 8'b10001000; // A
                        3'b010: SSD1 <= 8'b11000110; // C
                        3'b011: SSD1 <= 8'b10000110; // E
                        3'b100: SSD1 <= 8'b10001001; // H
                        3'b110: SSD1 <= 8'b11000111; // L
                        3'b111: SSD1 <= 8'b11000001; // U
                        default: SSD1 <= 8'b11111111; // OFF
                    endcase
                    case (braker_reg[3])
                        3'b000: SSD0 <= 8'b10001110; // F
                        3'b001: SSD0 <= 8'b10001000; // A
                        3'b010: SSD0 <= 8'b11000110; // C
                        3'b011: SSD0 <= 8'b10000110; // E
                        3'b100: SSD0 <= 8'b10001001; // H
                        3'b110: SSD0 <= 8'b11000111; // L
                        3'b111: SSD0 <= 8'b11000001; // U
                        default: SSD0 <= 8'b11111111; // OFF
                    endcase
                    LEDX <= check_result;
                    
                    // Move immediately to wait state
                    current_state <= 4'd11;
                end

                4'd11: begin
                    // --- STATE 11: WAIT FOR USER (New State) ---
                    // Keep displays active (critical)
                    case (braker_reg[0])
                        3'b000: SSD3 <= 8'b10001110; // F
                        3'b001: SSD3 <= 8'b10001000; // A
                        3'b010: SSD3 <= 8'b11000110; // C
                        3'b011: SSD3 <= 8'b10000110; // E
                        3'b100: SSD3 <= 8'b10001001; // H
                        3'b110: SSD3 <= 8'b11000111; // L
                        3'b111: SSD3 <= 8'b11000001; // U
                        default: SSD3 <= 8'b11111111; // OFF
                    endcase
                    case (braker_reg[1])
                        3'b000: SSD2 <= 8'b10001110; // F
                        3'b001: SSD2 <= 8'b10001000; // A
                        3'b010: SSD2 <= 8'b11000110; // C
                        3'b011: SSD2 <= 8'b10000110; // E
                        3'b100: SSD2 <= 8'b10001001; // H
                        3'b110: SSD2 <= 8'b11000111; // L
                        3'b111: SSD2 <= 8'b11000001; // U
                        default: SSD2 <= 8'b11111111; // OFF
                    endcase
                    case (braker_reg[2])
                        3'b000: SSD1 <= 8'b10001110; // F
                        3'b001: SSD1 <= 8'b10001000; // A
                        3'b010: SSD1 <= 8'b11000110; // C
                        3'b011: SSD1 <= 8'b10000110; // E
                        3'b100: SSD1 <= 8'b10001001; // H
                        3'b110: SSD1 <= 8'b11000111; // L
                        3'b111: SSD1 <= 8'b11000001; // U
                        default: SSD1 <= 8'b11111111; // OFF
                    endcase
                    case (braker_reg[3])
                        3'b000: SSD0 <= 8'b10001110; // F
                        3'b001: SSD0 <= 8'b10001000; // A
                        3'b010: SSD0 <= 8'b11000110; // C
                        3'b011: SSD0 <= 8'b10000110; // E
                        3'b100: SSD0 <= 8'b10001001; // H
                        3'b110: SSD0 <= 8'b11000111; // L
                        3'b111: SSD0 <= 8'b11000001; // U
                        default: SSD0 <= 8'b11111111; // OFF
                    endcase
                    LEDX <= check_result;
                    
                    // Wait for button press
                    if (brakerButtonRise) begin
                        // Check: Correct OR Lives ran out?
                        if (is_correct || lives == 0) begin
                            // Handle score update for loss case
                            if (!is_correct && lives == 0) begin
                                if (turn_A) begin
                                    score_A <= score_A + 1;
                                end
                                else begin
                                    score_B <= score_B + 1;
                                end
                            end
                            current_state <= 4'd9; // Show result
                        end
                        else begin
                            current_state <= 4'd6; // Retry
                            letter_count <= 0;
                        end
                    end
                end

                4'd9: begin
                    case (maker_reg[0])
                        3'b000: SSD3 <= 8'b10001110; // F
                        3'b001: SSD3 <= 8'b10001000; // A
                        3'b010: SSD3 <= 8'b11000110; // C
                        3'b011: SSD3 <= 8'b10000110; // E
                        3'b100: SSD3 <= 8'b10001001; // H
                        3'b110: SSD3 <= 8'b11000111; // L
                        3'b111: SSD3 <= 8'b11000001; // U
                        default: SSD3 <= 8'b11111111; // OFF
                    endcase
                    case (maker_reg[1])
                        3'b000: SSD2 <= 8'b10001110; // F
                        3'b001: SSD2 <= 8'b10001000; // A
                        3'b010: SSD2 <= 8'b11000110; // C
                        3'b011: SSD2 <= 8'b10000110; // E
                        3'b100: SSD2 <= 8'b10001001; // H
                        3'b110: SSD2 <= 8'b11000111; // L
                        3'b111: SSD2 <= 8'b11000001; // U
                        default: SSD2 <= 8'b11111111; // OFF
                    endcase
                    case (maker_reg[2])
                        3'b000: SSD1 <= 8'b10001110; // F
                        3'b001: SSD1 <= 8'b10001000; // A
                        3'b010: SSD1 <= 8'b11000110; // C
                        3'b011: SSD1 <= 8'b10000110; // E
                        3'b100: SSD1 <= 8'b10001001; // H
                        3'b110: SSD1 <= 8'b11000111; // L
                        3'b111: SSD1 <= 8'b11000001; // U
                        default: SSD1 <= 8'b11111111; // OFF
                    endcase
                    case (maker_reg[3])
                        3'b000: SSD0 <= 8'b10001110; // F
                        3'b001: SSD0 <= 8'b10001000; // A
                        3'b010: SSD0 <= 8'b11000110; // C
                        3'b011: SSD0 <= 8'b10000110; // E
                        3'b100: SSD0 <= 8'b10001001; // H
                        3'b110: SSD0 <= 8'b11000111; // L
                        3'b111: SSD0 <= 8'b11000001; // U
                        default: SSD0 <= 8'b11111111; // OFF
                    endcase
                    LEDX <= check_result;

                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        current_state <= 4'd10;
                    end 
                    else begin
                        timer_counter <= timer_counter + 1;
                    end
                end

                4'd10: begin
                    case(score_A)
                        2'd0: SSD3 <= 8'b11000000; // 0
                        2'd1: SSD3 <= 8'b11111001; // 1
                        2'd2: SSD3 <= 8'b10100100; // 2
                        default: SSD3 <= 8'b11000000;
                    endcase
                    SSD2 <= 8'b10111111; // -
                    SSD1 <= 8'b11111111;
                    case(score_B)
                        2'd0: SSD0 <= 8'b11000000; // 0
                        2'd1: SSD0 <= 8'b11111001; // 1
                        2'd2: SSD0 <= 8'b10100100; // 2
                        default: SSD0 <= 8'b11000000;
                    endcase

                    if (timer_counter >= 3) begin
                        timer_counter <= 0;
                        if (score_A == 2 || score_B == 2) begin
                            current_state <= 4'd0;
                            score_A <= 0; score_B <= 0; lives <= 3; turn_A <= 1;
                        end 
                        else begin
                            current_state <= 4'd1;
                            turn_A <= ~turn_A;
                            lives <= 3;
                        end
                    end 
                    else begin
                        timer_counter <= timer_counter + 1;
                    end
                end
                
                default: current_state <= 4'd0;
            endcase
        end
    end

endmodule
