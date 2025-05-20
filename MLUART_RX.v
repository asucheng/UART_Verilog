
`timescale 1ns / 1ps
//--------------------------------------------------------------
// Company: 
// Engineer: 
//
// Create Date:    15:11:20 09/24/2016
// Design Name: 
// Module Name:    MLUART_RX 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//--------------------------------------------------------------

module MLUART_RX (
    input           CLK_100MHZ,
    input           reset,
    input           clk_en_16_x_baud,
    input           UART_RX,
    output          read_data_complete,
    output  [7:0]   data_out  
);

//------------------------------------------------------------------
// Internal signals definition
//------------------------------------------------------------------
parameter   idle         = 4'd0,
            rstart       = 4'd1,
            rd0          = 4'd2,
            rd1          = 4'd3,
            rd2          = 4'd4,
            rd3          = 4'd5,
            rd4          = 4'd6,
            rd5          = 4'd7,
            rd6          = 4'd8,
            rd7          = 4'd9,
            rstop        = 4'd10,
            read_strobe  = 4'd11;

// Equivalent to tstateRX
reg [3:0] state, nstate;

// Equivalent to scount4 (4-bit counter)
reg [3:0] scount4;

// Equivalent to sdata_out
reg [7:0] data_out_reg;

// Equivalent to shift_reg
reg [7:0] shift_reg;

assign data_out = data_out_reg;

always @(posedge CLK_100MHZ) begin
    if (reset) begin
        state <= idle;
    end else begin
        state <= nstate;
    end
end

//------------------------------------------------------------------
// State Machine: transitions
// count 16 baud to move to next state
//------------------------------------------------------------------
always @(*) begin
    if (clk_en_16_x_baud == 1'b1) begin
        case (state)
            idle:         if (UART_RX == 1'b0) nstate = rstart;
            rstart:       if (scount4 == 4'hF) nstate = rd0;
            rd0:          if (scount4 == 4'hF) nstate = rd1;
            rd1:          if (scount4 == 4'hF) nstate = rd2;
            rd2:          if (scount4 == 4'hF) nstate = rd3;
            rd3:          if (scount4 == 4'hF) nstate = rd4;
            rd4:          if (scount4 == 4'hF) nstate = rd5;
            rd5:          if (scount4 == 4'hF) nstate = rd6;
            rd6:          if (scount4 == 4'hF) nstate = rd7;
            rd7:          if (scount4 == 4'hF) nstate = rstop;
            rstop:        nstate = read_strobe;
            read_strobe:  nstate = idle;
            default:      nstate = idle;
        endcase
    end
end

//------------------------------------------------------------------
// State Machine: output (control read_data_complete)
//------------------------------------------------------------------
// always @* begin
//     case (sstateRX)
//         read_strobe:       read_data_complete = 1'b1;
//         default:           read_data_complete = 1'b0;
//     endcase
// end
assign read_data_complete = (state == read_strobe);

//------------------------------------------------------------------
// datapath: update sdata_out
//------------------------------------------------------------------
always @(posedge CLK_100MHZ) begin
    if (reset) 
        data_out_reg <= 8'b00000000;
    else if (clk_en_16_x_baud == 1'b1) begin
        case (state)
            rstop:      data_out_reg <= shift_reg;
            default:    data_out_reg <= data_out_reg;
        endcase
    end
end

//------------------------------------------------------------------
// datapath: update scount4 (4-bit counter)
// 0-8 bits, start and stop bits would make counter + 1, becuase those are the bits need to be send.
//------------------------------------------------------------------
always @(posedge CLK_100MHZ) begin
    if (reset) 
        scount4 <= 4'd0;
    else if (clk_en_16_x_baud == 1'b1) begin
        case (state)
            rstart, rd0, rd1, rd2, rd3, rd4, rd5, rd6, rd7, rstop:
            scount4 <= scount4 + 4'd1;
            default:   scount4 <= 4'd0;
        endcase
    end
end

//------------------------------------------------------------------
// datapath: update shift_reg (bit shift to capture UART_RX)
//------------------------------------------------------------------
always @(posedge CLK_100MHZ) begin
    if (reset) 
        shift_reg <= 8'b00000000;
    else if (clk_en_16_x_baud == 1'b1) begin
        case (state)
            rd0, rd1, rd2, rd3, rd4, rd5, rd6, rd7: begin
                // Sample the bit when the 16x baud counter is 8
                if (scount4 == 4'h8)
                    shift_reg <= {UART_RX, shift_reg[7:1]};
            end
            default: ;
        endcase
    end
end

endmodule

