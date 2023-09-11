`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2023 01:46:56 AM
// Design Name: 
// Module Name: Reg_MUX
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


module Reg_MUX #(parameter BITS = 18 ,RSTTYPE = "SYNC" , SELECTION = 1 )
   (
    input clk , rst,en,
    input [BITS-1 : 0] in,
    output [BITS-1 :0 ] out
    );
    reg [BITS-1 :0 ] data ;
    generate 
    // piplined stage
        if(RSTTYPE == "SYNC" )
            begin
                always @(posedge clk )
                    begin
                        if(rst)
                           data<=0;
                         else if (en)
                          data <= in ;
                    end
            end
          else if (RSTTYPE == "ASYNC" )
            begin
                always @(posedge clk or negedge rst)
                    begin
                        if(rst)
                           data<=0;
                         else if (en)
                          data <= in ;
                    end
            end
    endgenerate
    // if selection == 1 => Piplined , if = 0 no piplined
    assign out = SELECTION ? data : in ;
endmodule
