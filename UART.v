`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/13/2025 01:11:40 PM
// Design Name: 
// Module Name: UART
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


module UART(
    input  clk,
    input  reset,
    input  data_in,
    output data_out
    );
    
    wire read_data_complete;
    wire [7:0] RX_out;
    
    wire sclk_en_16_x_baud;
    reg  [11:0] scount12       = 12'b0; 
    
    reg   send_data;
    wire  send_data_complete;
    reg  [7:0] TX_in;
    
    
    //instantiate RX
    MLUART_RX RX_module(
    .CLK_100MHZ(clk),
    .reset(reset),
    .clk_en_16_x_baud(sclk_en_16_x_baud),
    .UART_RX(data_in),
    .read_data_complete(read_data_complete),
    .data_out(RX_out)
    );
    
    //Instantiate TX
    MLUART_TX TX_module(
    .CLK_100MHZ(clk),
    .reset(reset),
    .clk_en_16_x_baud(sclk_en_16_x_baud),
    .data_in(RX_out),
    .send_data(send_data),
    .UART_TX(data_out),
    .send_data_complete(send_data_complete)
    );
    
    always @(posedge clk) begin
        if (read_data_complete) begin
            TX_in <= RX_out;     // Store received character for transmission
            send_data <= 1'b1;              // Start transmission
        end
        if (send_data_complete) begin
            send_data <= 1'b0;              // Reset send_data when transmission is done
        end
    end
    
    always @(posedge clk) begin
        if (scount12 >= 12'd54) begin
            scount12 <= 12'b0;
        end else begin
            scount12 <= scount12 + 12'd1;
        end
    end
    
    assign sclk_en_16_x_baud = (scount12 == 12'd54) ? 1'b1 : 1'b0;
    
endmodule
