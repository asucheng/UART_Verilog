`timescale 1ns / 1ps

module UART (
    input  wire         aclk,               // AXI Stream clock
    input  wire         BTN_UP,            // Active-low reset
    input  wire         UART_RX,      // UART RX (receive line)
    output wire         UART_TX,       //UART TX (transmit line)
    output reg [7:0]    LEDs
);

//------------------------------------------------------------------
// Internal signals
//------------------------------------------------------------------
//shared
reg  [11:0] scount12       = 12'b0;   // 12-bit counter
wire        sclk_en_16_x_baud;        // 16x baud enable pulse
wire        s_BTN_UP;

// AXI Stream Signals for RX FIFO
wire [7:0] rx_fifo_s_axis_tdata;  // Data from UART RX
wire       rx_fifo_s_axis_tvalid; // Valid from UART RX
wire       rx_fifo_s_axis_tready; // Ready from RX FIFO

wire [7:0] rx_fifo_m_axis_tdata;  // Data from RX FIFO to TX FIFO
wire       rx_fifo_m_axis_tvalid; // Valid from RX FIFO
wire       rx_fifo_m_axis_tready; // Ready for TX FIFO

wire [7:0] tx_fifo_m_axis_tdata;  // Data from TX FIFO to UART TX
wire       tx_fifo_m_axis_tvalid; // Valid from TX FIFO
wire       tx_fifo_m_axis_tready; // Ready for TX transmission

// FIFO Control Signals
wire fifo_almost_full_rx;  // RX FIFO Almost Full
wire fifo_almost_empty_tx; // TX FIFO Almost Empty

//------------------------------------------------------------------
// Instantiate the MLUART_RX module
//------------------------------------------------------------------
UART_RX_AXIS RX_inst (
    .aclk(aclk),
    .aresetn(s_BTN_UP),
    .UART_RX(UART_RX),
    .clk_en_16_x_baud(sclk_en_16_x_baud),
    .m_axis_tdata(rx_fifo_s_axis_tdata),
    .m_axis_tvalid(rx_fifo_s_axis_tvalid),
    .m_axis_tready(rx_fifo_s_axis_tready),
    .fifo_almost_full(fifo_almost_full_rx)
);

//------------------------------------------------------------------
// Instantiate RX FIFO
//------------------------------------------------------------------
axis_data_fifo_0 fifo_rx (
    .s_axis_aclk(aclk),
    .s_axis_aresetn(s_BTN_UP),
    .s_axis_tdata(rx_fifo_s_axis_tdata),
    .s_axis_tvalid(rx_fifo_s_axis_tvalid),
    .s_axis_tready(rx_fifo_s_axis_tready),
    .m_axis_tdata(rx_fifo_m_axis_tdata),
    .m_axis_tvalid(rx_fifo_m_axis_tvalid),
    .m_axis_tready(rx_fifo_m_axis_tready),
    .almost_full(fifo_almost_full_rx),
    .almost_empty()
);

//------------------------------------------------------------------
// Instantiate TX FIFO
//------------------------------------------------------------------
axis_data_fifo_0 fifo_tx (
    .s_axis_aclk(aclk),
    .s_axis_aresetn(s_BTN_UP),
    .s_axis_tdata(rx_fifo_m_axis_tdata),  
    .s_axis_tvalid(rx_fifo_m_axis_tvalid), 
    .s_axis_tready(rx_fifo_m_axis_tready), 
    .m_axis_tdata(tx_fifo_m_axis_tdata),  
    .m_axis_tvalid(tx_fifo_m_axis_tvalid), 
    .m_axis_tready(tx_fifo_m_axis_tready), 
    .almost_full(),  
    .almost_empty(fifo_almost_empty_tx)  
);

//------------------------------------------------------------------
// Instantiate the MLUART_TX module
//------------------------------------------------------------------
UART_TX_AXIS TX_inst (
    .aclk(aclk),
    .aresetn(s_BTN_UP),
    .s_axis_tdata(tx_fifo_m_axis_tdata),
    .s_axis_tvalid(tx_fifo_m_axis_tvalid),
    .s_axis_tready(tx_fifo_m_axis_tready),
    .UART_TX(UART_TX),
    .clk_en_16_x_baud(sclk_en_16_x_baud),
    .fifo_almost_empty(fifo_almost_empty_tx)
);

//------------------------------------------------------------------
// add LED for debug
//------------------------------------------------------------------
always @(posedge aclk) begin 
    if (sclk_en_16_x_baud) begin
        LEDs <= rx_fifo_s_axis_tdata;
    end
end
//------------------------------------------------------------------
// 12-bit counter to generate sclk_en_16_x_baud
//   For 115200 baud at 16x oversampling:
// every 651 cycles clk_en_16_x_baud would toggle once
//------------------------------------------------------------------
always @(posedge aclk) begin
    if (scount12 >= 12'd54) begin
        scount12 <= 12'b0;
    end else begin
        scount12 <= scount12 + 12'd1;
    end
end

//------------------------------------------------------------------
// Generate the 16x baud enable pulse
//   '1' when scount12 == 0x36, otherwise '0'
//------------------------------------------------------------------
assign sclk_en_16_x_baud = (scount12 == 12'h36) ? 1'b1 : 1'b0;

assign s_BTN_UP = !BTN_UP;

endmodule

