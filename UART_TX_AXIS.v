`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2025 12:50:49 AM
// Design Name: 
// Module Name: UART_TX_AXIS
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


module UART_TX_AXIS #(parameter DATA_WIDTH = 8)(
    input  wire        aclk,               // AXI Stream clock
    input  wire        aresetn,            // Active-low reset
    input  wire        clk_en_16_x_baud,   // Baud clock enable
    input  wire        fifo_almost_empty,   // FIFO almost empty (INPUT)
    input  wire [7:0]  s_axis_tdata,       // AXI Stream input data
    input  wire        s_axis_tvalid,      // AXI Stream valid signal
    output reg         s_axis_tready,      // AXI Stream ready signal
    output wire        UART_TX            // UART transmit line
);

//------------------------------------------------------------------
// State Machine Definition
//------------------------------------------------------------------
localparam IDLE = 2'b00, 
           SEND = 2'b01;
//           WAIT = 2'b10;

reg [1:0] current_state, next_state;

//------------------------------------------------------------------
// Internal signals
//------------------------------------------------------------------
reg [DATA_WIDTH-1:0] tx_data; // Holds the data to be transmitted
reg tx_start;                 // Start transmission
wire send_data_complete;       // UART TX completion flag
//wire s_axis_tready_i;

//------------------------------------------------------------------
// Instantiate `MLUART_TX` (UART Transmitter)
//------------------------------------------------------------------
MLUART_TX uart_tx (
    .CLK_100MHZ(aclk),
    .reset(!aresetn),
    .clk_en_16_x_baud(clk_en_16_x_baud),
    .data_in(tx_data),         // Data to send
    .send_data(tx_start),      // Trigger TX
    .UART_TX(UART_TX),         // UART output
    .send_data_complete(send_data_complete)
);

//------------------------------------------------------------------
// State Transition Logic (No `LOAD` State)
//------------------------------------------------------------------
always @(posedge aclk) begin
    if (!aresetn)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

//------------------------------------------------------------------
// Next State Logic
//------------------------------------------------------------------
always @(*) begin
    case (current_state)
        IDLE: begin
            if (s_axis_tvalid && !fifo_almost_empty)   //AXI Handshake
                next_state = SEND;
            else
                next_state = IDLE;
        end
        
        SEND: begin
            if (send_data_complete)              //Wait until UART TX is done
                next_state = IDLE;
            else
                next_state = SEND;
        end
        
        default: next_state = IDLE;
    endcase
end

//always @(*) begin
//    case (current_state)
//        IDLE: begin
//            if (s_axis_tvalid)   //AXI Handshake
//                next_state = SEND;
//            else
//                next_state = IDLE;
//        end
        
//        SEND: begin
//            if (!fifo_almost_empty)              //Wait until UART TX is done
//                next_state = WAIT;
//            else
//                next_state = SEND;
//        end
        
//        WAIT: begin
//            if (send_data_complete) begin
//                next_state = IDLE;
//            end else
//                next_state = WAIT;
//        end
        
//        default: next_state = IDLE;
//    endcase
//end





//------------------------------------------------------------------
// Output Logic (AXI Stream & UART)
//------------------------------------------------------------------
always @(posedge aclk) begin
    if (!aresetn) begin
        s_axis_tready <= 1'b0;  // Ready to receive data initially
        tx_data <= 8'b0;
        tx_start <= 1'b0;
    end else begin
        case (current_state)
            IDLE: begin
                if (s_axis_tvalid && !fifo_almost_empty) begin  // AXI Handshake
                    tx_data <= s_axis_tdata;               // Capture incoming AXI data
                    s_axis_tready <= 1'b1;                 // Deassert ready after accepting data
                    tx_start <= 1'b1;                      // Start UART transmission immediately
                end 
            end

            SEND: begin
                if (send_data_complete) begin
                    tx_start <= 1'b0;                      // Clear send trigger
                    s_axis_tready <= 1'b0;                 // Ready for next data
                end
            end
        endcase
    end
end

//always @(posedge aclk) begin
//    if (!aresetn) begin
//        s_axis_tready <= 1'b0;  // Ready to receive data initially
//        tx_data <= 8'b0;
//        tx_start <= 1'b0;
//    end else begin
//        case (current_state)
//            IDLE: begin
//                if (s_axis_tvalid) begin  // AXI Handshake
////                    tx_data <= s_axis_tdata;               // Capture incoming AXI data
//                    s_axis_tready <= 1'b0;                 // Deassert ready after accepting data
//                    tx_start <= 1'b0;                      // Start UART transmission immediately
//                end 
//            end

//            SEND: begin
//                if (!fifo_almost_empty) begin
//                    tx_data <= s_axis_tdata;               // Capture incoming AXI data
//                    tx_start <= 1'b1;                      // Clear send trigger
//                    s_axis_tready <= 1'b1;                 // Ready for next data
//                end
//            end
            
//            WAIT: begin
////                s_axis_tready <= 1'b0;                 // Ready for next data
////                tx_start <= 1'b0;                      // Clear send trigger
//                if (send_data_complete) begin
//                    tx_start <= 1'b0;                      // Clear send trigger
//                    s_axis_tready <= 1'b0;                 // Ready for next data
//                end
//            end
//        endcase
//    end
//end

        
endmodule
