`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2025 03:10:55 PM
// Design Name: 
// Module Name: UART_RX_AXIS
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
module UART_RX_AXIS(
    input  wire                     aclk,              // AXI Stream clock
    input  wire                     aresetn,           // Active-low reset
    input  wire                     UART_RX,           // UART receive line
    input  wire                     clk_en_16_x_baud,  // Baud clock enable
    input  wire                     m_axis_tready,     // AXI Stream ready signal
    input  wire                     fifo_almost_full,  // FIFO almost full flag
    output reg                      m_axis_tvalid,     // AXI Stream valid signal
    output reg [7:0]                m_axis_tdata       // AXI Stream data output
    );
    
//------------------------------------------------------------------
// Define State Machine States
//------------------------------------------------------------------
parameter  IDLE = 0,
           SEND = 1;
           
reg current_state, next_state;

//------------------------------------------------------------------
// Internal signals definition
//------------------------------------------------------------------
wire [7:0] read_data;    //output wrapper singal for m_axis_tdata
wire read_data_complete;            //output wrapper signal 
    
//------------------------------------------------------------------
// Instantiate UART TX Module
//------------------------------------------------------------------
MLUART_RX uart_rx (
    .CLK_100MHZ(aclk),
    .reset(!aresetn),
    .clk_en_16_x_baud(clk_en_16_x_baud),
    .read_data_complete(read_data_complete),
    .data_out(read_data),
    .UART_RX(UART_RX)
);

//------------------------------------------------------------------
// State Transition Logic
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
            if (read_data_complete && !fifo_almost_full) //This read_data_complete signal waits all bits in a byte received then go to axis handshake 
                next_state = SEND;
            else
                next_state = IDLE;
        end
        
        SEND: begin
            if (m_axis_tready) 
                next_state = IDLE;
            else
                next_state = SEND;
        end
        
        default: next_state = IDLE;
    endcase
end

//------------------------------------------------------------------
// Output Logic (AXI Stream Signals)
//------------------------------------------------------------------
always @(posedge aclk) begin
    if (!aresetn) begin
        m_axis_tvalid <= 1'b0;
        m_axis_tdata  <= 8'b0;
    end else begin
        case (current_state)
            IDLE: begin
                //m_axis_tvalid <= 1'b0;
                if (read_data_complete && !fifo_almost_full) begin
                    m_axis_tdata  <= read_data;  // Capture data before sending
                    m_axis_tvalid <= 1'b1;       // Assert valid signal
                end else begin
                    m_axis_tvalid <= m_axis_tvalid;
                end
            end
            
            SEND: begin
                if (m_axis_tready) begin
                    m_axis_tvalid <= 1'b0;  // Clear valid after transfer
                end else
                    m_axis_tvalid <= m_axis_tvalid;
            end
        endcase
    end
end
    
endmodule
