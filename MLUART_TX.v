`timescale 1ns / 1ps

module MLUART_TX(
    input         CLK_100MHZ,         // 100 MHz FPGA clock
    input         reset,
    input         clk_en_16_x_baud,   // 16x baud rate enable
    input  [7:0]  data_in,            // Data to send (ASCII character)
    input         send_data,          // Start transmission when HIGH
    output        UART_TX,            // UART transmit line
    output        send_data_complete  // Indicates when transmission is done
    );
    
//------------------------------------------------------------------
// State Machine States
//------------------------------------------------------------------
parameter [3:0] 
                idle        = 4'd0,  // Wait for new data
                tstart      = 4'd1,  // Transmit start bit
                td0         = 4'd2,  // Transmit data bit 0
                td1         = 4'd3,  // Transmit data bit 1
                td2         = 4'd4,  // Transmit data bit 2
                td3         = 4'd5,  // Transmit data bit 3
                td4         = 4'd6,  // Transmit data bit 4
                td5         = 4'd7,  // Transmit data bit 5
                td6         = 4'd8,  // Transmit data bit 6
                td7         = 4'd9,  // Transmit data bit 7
                tstop       = 4'd10, // Transmit stop bit
                send_strobe = 4'd11; // Transmission complete

//reg [3:0] tstateTX = idle;  // TX state machine
reg [3:0] state, next_state;
reg [3:0] scount4; // 4-bit counter
reg UART_TX_r;

always @(posedge CLK_100MHZ) begin
    if (reset) 
        state <= idle;
    else
        state <= next_state;
end

//------------------------------------------------------------------
// State Machine: transitions
//------------------------------------------------------------------
always @(*) begin
    if (clk_en_16_x_baud == 1'b1) begin
        case (state)
            idle:       if (send_data == 1'b1) next_state = tstart;
            tstart:      if (scount4 == 4'hF) next_state = td0;
            td0:         if (scount4 == 4'hF) next_state = td1;
            td1:         if (scount4 == 4'hF) next_state = td2;
            td2:         if (scount4 == 4'hF) next_state = td3;
            td3:         if (scount4 == 4'hF) next_state = td4;
            td4:         if (scount4 == 4'hF) next_state = td5;
            td5:         if (scount4 == 4'hF) next_state = td6;
            td6:         if (scount4 == 4'hF) next_state = td7;
            td7:         if (scount4 == 4'hF) next_state = tstop;
            tstop:       next_state = send_strobe;
            send_strobe: next_state = idle;
            default:     next_state = idle;
        endcase
    end
end

//------------------------------------------------------------------
// State Machine: output (control read_data_complete)
//------------------------------------------------------------------
assign send_data_complete = (state == send_strobe);
assign UART_TX = UART_TX_r;

//------------------------------------------------------------------
// datapath: update sdata_read (bit shift to capture UART_RX)
//------------------------------------------------------------------
always @(posedge CLK_100MHZ) begin
    if (reset)
        UART_TX_r <= 1'b1;
    else if (clk_en_16_x_baud == 1'b1) begin
        case (state)
            idle:       UART_TX_r <= 1'b1; // Load input data
            tstart:     UART_TX_r <= 1'b0;     // Start bit LOW
            td0:        UART_TX_r <= data_in[0];
            td1:        UART_TX_r <= data_in[1];
            td2:        UART_TX_r <= data_in[2];
            td3:        UART_TX_r <= data_in[3];
            td4:        UART_TX_r <= data_in[4];
            td5:        UART_TX_r <= data_in[5];
            td6:        UART_TX_r <= data_in[6];
            td7:        UART_TX_r <= data_in[7];
            tstop:      UART_TX_r <= 1'b1;     // Stop bit HIGH
            default:    UART_TX_r <= 1'b1;     // Idle state HIGH
        endcase
    end
end
//------------------------------------------------------------------
// 4-bit Counter for Bit Timing
//------------------------------------------------------------------
always @(posedge CLK_100MHZ) begin
    if (clk_en_16_x_baud == 1'b1) begin
        case (state)
            tstart, td0, td1, td2, td3, td4, td5, td6, td7, tstop: 
                scount4 <= scount4 + 4'd1;
            default: 
                scount4 <= 4'd0;
        endcase
    end
end

    
endmodule
