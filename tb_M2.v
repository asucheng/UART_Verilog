`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2025 05:48:55 PM
// Design Name: 
// Module Name: tb_M2
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


module tb_M2();

    // ? Testbench Signals
    reg         aclk;
    reg         BTN_UP;
    reg         UART_RX;
    wire        UART_TX;
    wire [7:0]  LEDs;

    // ? Clock Period Definitions
    parameter CLK_100MHZ_period = 10;
    parameter CLK_16xbaud = CLK_100MHZ_period * 54 * 16; // For 115200 baud at 16x oversampling

    reg [9:0] DATA; // ? 10-bit UART Frame (Start + 8 Data + Stop)
    reg start_bit, stop_bit;
    
    // ? Instantiate the DUT (UART Module)
    UART uut (
        .aclk(aclk),
        .BTN_UP(BTN_UP),
        .UART_RX(UART_RX),
        .UART_TX(UART_TX),
        .LEDs(LEDs)
    );

    // ? Clock Generation Process (100 MHz)
    always begin
        # (CLK_100MHZ_period / 2) aclk = ~aclk;
    end

    // ? Task: Send UART Byte (UART_RX)
    task send_uart_byte(input [7:0] byte);
        integer i;
        begin
            DATA = {1'b1, byte, 1'b0}; // ? Start Bit + Data + Stop Bit
            
            for (i = 0; i < 10; i = i + 1) begin
                UART_RX = DATA[i]; // ? Send each bit
                #(CLK_16xbaud); // ? Wait for 1 baud time
            end
        end
    endtask

    // ? Task: Receive UART Byte (UART_TX)
    task receive_uart_byte(output [7:0] received_byte);
        integer i;
        begin
            
            start_bit = UART_TX;
            for (i = 0; i < 8; i = i + 1) begin
                #(CLK_16xbaud); // Sample each data bit at the correct interval
                received_byte[i] = UART_TX;
            end
            #(CLK_16xbaud);
            stop_bit = UART_TX;
        end
    endtask

    // ? Main Test Sequence
    integer i;
    reg [7:0] tx_data [0:15];  // ? Sent Data
    reg [7:0] rx_data [0:15];  // FPGA receive data

    initial begin
        //Initialize Signals
        aclk = 0;
        BTN_UP = 1;
        UART_RX = 1; // ? Idle UART Line
        #100000;
        BTN_UP = 0;
        
        // ? Send 16 Bytes of Data
        for (i = 0; i < 16; i = i + 1) begin
            rx_data[i] = i + 8'h30; // Send ASCII '0' to 'F'
            send_uart_byte(rx_data[i]);
            receive_uart_byte(tx_data[i]);
        end
        
        receive_uart_byte(tx_data[i]);

        // ? Receive 16 Bytes of Data
//        for (i = 0; i < 2; i = i + 1) begin
//            receive_uart_byte(rx_data[i]);
//        end

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
