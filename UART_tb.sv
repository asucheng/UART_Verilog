`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/12/2025 06:34:35 PM
// Design Name: 
// Module Name: UART_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module UART_tb();

    reg clk;
    reg reset;
    reg data_in;
    reg data_out;
    
    reg [9:0] DATA; // ? 10-bit UART Frame (Start + 8 Data + Stop)
    reg start_bit, stop_bit;
    parameter CLK_16xbaud = 10 * 54 * 16; // For 115200 baud at 16x oversampling

    
    //instantiate UART
    UART dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
    );
    
    //generate clock
    initial begin 
        clk = 1'b0;
        forever #5 clk = !clk;
    end
    
    //generate reset
    initial begin 
        reset = 1'b1;
        #10;
        reset = 1'b0;
    end
    
    task send_uart_byte(input [7:0] byte_data);
        integer i;
        begin
            DATA = {1'b1, byte_data, 1'b0}; // ? stop Bit + Data + start Bit
            
            for (i = 0; i < 10; i = i + 1) begin
                data_in = DATA[i]; // ? Send each bit
                #(CLK_16xbaud); // ? Wait for 1 baud time
            end
        end
    endtask
    
    //Task: Receive UART Byte (UART_TX)
    task receive_uart_byte(output [7:0] received_byte);
        integer i;
        begin
            
            start_bit = data_out;
            for (i = 0; i < 8; i = i + 1) begin
                #(CLK_16xbaud); // Sample each data bit at the correct interval
                received_byte[i] = data_out;
            end
            #(CLK_16xbaud);
            stop_bit = data_out;
        end
    endtask
    
    integer i;
    reg [7:0] tx_data [0:15];  // ? Sent Data
    reg [7:0] rx_data [0:15];  // FPGA receive data
    
    //test stimuli
    initial begin 
//        data_in = 1'b1;
        
        // ? Send 16 Bytes of Data
        for (i = 0; i < 16; i = i + 1) begin
            rx_data[i] = i + 8'h30; // Send ASCII '0' to 'F'
            send_uart_byte(rx_data[i]);
            receive_uart_byte(tx_data[i]);
        end
        
        receive_uart_byte(tx_data[i]);

        // ? Verify Received Data
        for (i = 0; i < 16; i = i + 1) begin
            if (rx_data[i] !== tx_data[i]) begin
                $display("Test Failed: Mismatch at byte %d: Sent %h, Received %h", i, tx_data[i], rx_data[i]);
                $stop;
            end
        end

        // ? If all bytes match, test passes
        $display("Test Passed: All 16 bytes correctly received!");
        $finish;
    end
    
    
    
    
            
    
endmodule
