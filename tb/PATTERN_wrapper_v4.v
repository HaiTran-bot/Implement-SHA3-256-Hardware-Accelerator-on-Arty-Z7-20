`timescale 1ns / 1ps
`define CYCLE_TIME 10
`define End_CYCLE  100000000

module PATTERN_wrapper_v4();

    // ===============================================================
    // Input & Output Declaration
    // ===============================================================
    reg clk, rst_n, in_valid, out_ready, in_done;
    reg [31:0] in_data;

    wire out_valid, in_ready;
    wire [31:0] out_data;
    wire busy;
    
    // ===============================================================
    // UUT Instantiation
    // ===============================================================
    wrapper_v4 uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .in_data(in_data),
        .in_done(in_done),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data(out_data),
        .busy(busy)
    );

    // ===============================================================
    // Parameters & Variables
    // ===============================================================
    integer golden_read;
    integer patcount, output_count;
    integer gap;
    integer a;
    integer i, j;
    parameter PATNUM = 8;

    // Biến chứa toàn bộ dòng hex (1600 bit) và Hash chuẩn (256 bit)
    reg [1599:0] full_golden_state; 
    reg [255:0]  expected_hash_gold;
    
    // Buffer input
    reg [31:0] in_data_reg[0:49];
    reg read_done;

    // ===============================================================
    // Clock
    // ===============================================================
    always #5 clk = ~clk;
    initial clk = 0;

    // ===============================================================
    // Initial Block
    // ===============================================================
    initial begin
        rst_n    = 1'b1;
        in_valid = 1'b0;
        out_ready = 1'b1;
        in_done = 0;
        in_data = 0;
        
        // Mở file (Cập nhật đường dẫn file của bạn ở đây)
        golden_read  = $fopen("D:/HK251/BTL_TKLL/testcase/wrapper_tb_v4.txt","r");
        if (golden_read == 0) begin
            $display("Error: Cannot open golden file!");
            $finish;
        end
        
        @(negedge clk);
        for (patcount=0; patcount<PATNUM; patcount=patcount+1) begin		
            // --- QUAN TRỌNG: Reset thật sạch trước mỗi pattern ---
            reset_task; 
            
            read_done = 0;
            in_done = 0;
            $display("\033[1;44mStart Pattern %02d\033[0;1m\n\033[0;33m[Input Data]\033[0;0m", patcount);
            
            while(read_done==0) begin
                load_golden;
                input_task;
                
                if(!read_done) begin
                    while(!in_ready) @(negedge clk);
                end
                else begin
                    gap = $urandom_range(2,4);
                    repeat(gap) @(negedge clk);
                end
            end
            
            $display();
            check_answer;
            @(negedge clk);
        end
        
        #(1000);
        $display("\033[1;32m\033[5m[Pass] Congratulation You Pass All of the Testcases!!!\033[0;1m");
        $finish;
    end 

    // ===============================================================
    // TASK: Reset
    // ===============================================================
    task reset_task;
    begin
        rst_n = 1;
        #(20); 
        rst_n = 0; // Kéo Reset xuống
        
        // --- Xóa sạch tín hiệu đầu vào để tránh lọt dữ liệu rác ---
        in_valid = 0;
        in_data = 0; 
        in_done = 0;
        out_ready = 1;
        
        #(100);    // Giữ reset đủ lâu
        rst_n = 1; // Thả Reset
        #(20);
    end 
    endtask

    // ===============================================================
    // TASK: Load Golden Data
    // ===============================================================
    reg [31:0] curr_in_reg;
    reg [7:0] reg1, reg2, reg3, reg4;
    integer t, t2, round_t;
    reg [9:0] len_reg;
    reg in_done_reg;

    task load_golden; 
    begin
        a = $fscanf(golden_read, "%d\n", in_done_reg);
        a = $fscanf(golden_read, "%d\n", len_reg);
        
        if(in_done_reg==1) read_done = 1;
        
        t = 0;
        round_t = 0;
        for(i=0; i<50; i=i+1) in_data_reg[i] = 0;
        
        while(t != len_reg) begin
            t2 = len_reg - t;
            if(t2 >= 4) begin
                a = $fscanf(golden_read, "%c", reg1);
                a = $fscanf(golden_read, "%c", reg2);
                a = $fscanf(golden_read, "%c", reg3);
                a = $fscanf(golden_read, "%c", reg4);
                t = t + 4;
                $write("%s%s%s%s", reg1, reg2, reg3, reg4);
                curr_in_reg = {reg4, reg3, reg2, reg1}; 
            end
            else begin
                case(t2)
                    1: begin
                        a = $fscanf(golden_read, "%c", reg1);
                        reg2=0; reg3=0; reg4=0; t=t+1;
                        $write("%s", reg1);
                        curr_in_reg = {reg4, reg3, reg2, reg1};
                    end
                    2: begin
                        a = $fscanf(golden_read, "%c", reg1);
                        a = $fscanf(golden_read, "%c", reg2);
                        reg3=0; reg4=0; t=t+2;
                        $write("%s%s", reg1, reg2);
                        curr_in_reg = {reg4, reg3, reg2, reg1};
                    end
                    3: begin
                        a = $fscanf(golden_read, "%c", reg1);
                        a = $fscanf(golden_read, "%c", reg2);
                        a = $fscanf(golden_read, "%c", reg3);
                        reg4=0; t=t+3;
                        $write("%s%s%s", reg1, reg2, reg3);
                        curr_in_reg = {reg4, reg3, reg2, reg1};
                    end
                endcase
            end
            if (round_t < 50) in_data_reg[round_t] = curr_in_reg;
            round_t = round_t + 1;
        end
        
        if(read_done) begin
            a = $fscanf(golden_read, "%h\n", full_golden_state);
            expected_hash_gold = full_golden_state[1599:1344]; 
        end
    end 
    endtask

    // ===============================================================
    // TASK: Input Driver
    // ===============================================================
    task input_task;
    begin
        @(negedge clk);
        in_valid = 1'b1;
        for(i = 0; i < 34; i = i + 1) begin
            if (i < 50) in_data = in_data_reg[i];
            else in_data = 0;
            
            @(negedge clk);
            in_valid = 1'b0;
            in_data = 0; // Quan trọng: Xóa data để tránh rác

            if(i == ((len_reg-1)/4)) begin
                gap = $urandom_range(2,4);
                repeat(gap) @(negedge clk);
                in_done = in_done_reg;
            end

            if(in_done) begin
                @(negedge clk);
                in_valid = 1'b0;
                in_data = 0;
                i = 35; // Break
            end
            else begin
                gap = $urandom_range(2,4);
                repeat(gap) @(negedge clk);
                in_valid = 1'b1;
            end
        end
        in_valid = 1'b0;
        in_data = 0; 
    end 
    endtask

    // ===============================================================
    // TASK: Check Answer
    // ===============================================================
    reg [255:0] calculated_hash;
    reg [31:0]  words_received [0:7];
    
    task check_answer;
    begin
        while(out_valid == 0) begin
            @(negedge clk);
        end
       
        output_count = 0;
        
        // 1. Nhận đủ 8 từ (32-bit) từ Wrapper
        while(output_count < 8) begin
            words_received[output_count] = out_data;
            output_count = output_count + 1;
            @(negedge clk);
            
            out_ready = 0;
            gap = $urandom_range(2,4);
            repeat(gap) @(negedge clk);
            out_ready = 1;
            
            if (output_count < 8) begin
                while(out_valid == 0) @(negedge clk);
            end
        end
        
        calculated_hash = {
            words_received[1], words_received[0], 
            words_received[3], words_received[2], 
            words_received[5], words_received[4], 
            words_received[7], words_received[6]  
        };
        
        $display ("\033[0;33m[Calculate Hash]\033[0;0m\n%h", calculated_hash);
        
        if (calculated_hash == expected_hash_gold) begin
            $display("\033[1;32m[Pass] \033[1;0m\n");
        end else begin
            $display("\033[1;31m[FAIL] \033[1;0m");
            $display("Expected: %h", expected_hash_gold);
            $display("Got     : %h\n", calculated_hash);
            $finish; 
        end
    end 
    endtask

endmodule