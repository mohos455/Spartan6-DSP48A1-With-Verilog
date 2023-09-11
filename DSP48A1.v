`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2023 01:59:54 AM
// Design Name: 
// Module Name: DSP48A1
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


module DSP48A1 #(parameter A0REG =0 , A1REG =1 ,B0REG = 0 , B1REG = 1 ,CREG =1 ,DREG = 1 ,MREG = 1, 
PREG =1, CARRYINREG = 1 ,CARRYOUTREG =1 ,OPMODEREG =1,
CARRYINSEL = "OPMODE5" , B_INPUT = "DIRECT" , RSTTYPE = "SYNC")(
    input clk, carryin,
    input [17 :0 ] A,
    input [17 :0 ] B,
    input [47 :0 ] C,
    input [17:0 ] D,
    input [ 7 : 0 ] opmode,
    input [17 :0 ] BCIN ,
    input RSTA,RSTB,RSTM,RSTP,RSTC,RSTD,RSTCARRYIN,RSTOPMODE,
    input CEA,CEB,CEM,CEP,CEC,CED,CECARRTIN,CEOPMODE,
    input [47 :0 ] PCIN,
    output [17 :0 ] BCOUT,
    output [47:0] PCOUT,
    output [47 :0 ] P ,
    output [35:0] M,
    output CARRYOUT , CARRYOUTF
    );
    
    // DATA PATHS
    wire [17:0] D0_OUT , B0_IN , B0_OUT , A0_OUT,B1_IN,B1_OUT,A1_OUT;
    wire [17 :0 ] PRE_OUT ;
    wire [35:0 ]M_IN , M_OUT;
    wire CYI_IN , CYI_OUT,CYO_IN,CYO_OUT;
    wire [47:0 ] POST_OUT, P_OUT,C0_OUT;
    reg [47:0] MUX_X_OUT , MUX_Z_OUT;
    wire [7:0] OP_OUT;
    ////////////
    
    /// first stage
    //opmode
    Reg_MUX #(.BITS(8),.RSTTYPE(RSTTYPE),.SELECTION(OPMODEREG)) OP_MUX (
        .clk(clk),
        .in(opmode),
        .out(OP_OUT),
        .en(CEOPMODE),
        .rst(RSTOPMODE)
        );
    //D input
    Reg_MUX #(.BITS(18),.RSTTYPE(RSTTYPE),.SELECTION(DREG)) D_MUX (
        .clk(clk),
        .in(D),
        .out(D0_OUT),
        .en(CED),
        .rst(RSTD)
        );
        // B IN
        assign B0_IN = (B_INPUT == "DIRECT") ? B : (B_INPUT == "CASCADE") ? BCIN : 0; 
         Reg_MUX #(.BITS(18),.RSTTYPE(RSTTYPE),.SELECTION(B0REG)) B_MUX (
        .clk(clk),
        .in(B0_IN),
        .out(B0_OUT),
        .en(CEB),
        .rst(RSTB)
        );
        // A INPUT
    Reg_MUX #(.BITS(18),.RSTTYPE(RSTTYPE),.SELECTION(A0REG)) A_MUX (
        .clk(clk),
        .in(A),
        .out(A0_OUT),
        .en(CEA),
        .rst(RSTA)
        );
     // C INPUT 
     Reg_MUX #(.BITS(48),.RSTTYPE(RSTTYPE),.SELECTION(CREG)) C_MUX (
        .clk(clk),
        .in(C),
        .out(C0_OUT),
        .en(CEC),
        .rst(RSTC)
        );
        //////////////
        
        // //SECEND STAGE
        // PRE-ADDER-SUB
        assign PRE_OUT = (OP_OUT[6]) ? (D0_OUT-B0_OUT):(D0_OUT+B0_OUT)  ;
        assign B1_IN = (OP_OUT[4]) ? PRE_OUT :B0_OUT ;
        // B IN
        assign B0_IN = (B_INPUT == "DIRECT") ? B : (B_INPUT == "CASCADE") ? BCIN : 0; 
         Reg_MUX #(.BITS(18),.RSTTYPE(RSTTYPE),.SELECTION(B1REG)) B1_MUX (
        .clk(clk),
        .in(B1_IN),
        .out(B1_OUT),
        .en(CEB),
        .rst(RSTB)
        );
        // A INPUT
    Reg_MUX #(.BITS(18),.RSTTYPE(RSTTYPE),.SELECTION(A1REG)) A1_MUX (
        .clk(clk),
        .in(A0_OUT),
        .out(A1_OUT),
        .en(CEA),
        .rst(RSTA)
        );
        
        /// 3rd stage multi[layer
        assign  M_IN = A1_OUT * B1_OUT ;
               // M INPUT
    Reg_MUX #(.BITS(36),.RSTTYPE(RSTTYPE),.SELECTION(MREG)) M_MUX (
        .clk(clk),
        .in(M_IN),
        .out(M_OUT),
        .en(CEM),
        .rst(RSTM)
        );
       // CYI
        assign CYI_IN = (CARRYINSEL == "OPMODE5") ? OP_OUT[5] : (CARRYINSEL == "CARRYIN") ? carryin : 0;
        
        Reg_MUX #(.BITS(1),.RSTTYPE(RSTTYPE),.SELECTION(CARRYINREG)) CYI_MUX (
        .clk(clk),
        .in(CYI_IN),
        .out(CYI_OUT),
        .en(CECARRTIN),
        .rst(RSTCARRYIN)
        );
        //////////////////////////
       // 4INMUX 
       // X mux
       always @(*)
       begin
        case(OP_OUT[1:0])
        2'b00 : MUX_X_OUT = 48'b0;
        2'b01 : MUX_X_OUT = {12'b0 , M_OUT};
        2'b10 : MUX_X_OUT = P_OUT ;
        2'b11 : MUX_X_OUT = {D0_OUT[11:0] ,A0_OUT ,B0_OUT };
        endcase
       end
       // Z mux 
       always @(*)
       begin
        case(OP_OUT[3:2])
        2'b00 : MUX_Z_OUT = 48'b0;
        2'b01 : MUX_Z_OUT = PCIN;
        2'b10 : MUX_Z_OUT = P_OUT ;
        2'b11 : MUX_Z_OUT = C0_OUT ;
        endcase
       end
       ///// POST ADDER SUB
       //
       assign {CYO_IN ,POST_OUT} = (OP_OUT[7]) ? (MUX_Z_OUT-(MUX_X_OUT+CYI_OUT)):(MUX_Z_OUT +(MUX_X_OUT+CYI_OUT))  ;
       // CYO
        Reg_MUX #(.BITS(1),.RSTTYPE(RSTTYPE),.SELECTION(CARRYOUTREG)) CYO_MUX (
        .clk(clk),
        .in(CYO_IN),
        .out(CYO_OUT),
        .en(CECARRTIN),
        .rst(RSTCARRYIN)
        );
        // P 
         Reg_MUX #(.BITS(48),.RSTTYPE(RSTTYPE),.SELECTION(PREG)) P_MUX (
        .clk(clk),
        .in(POST_OUT),
        .out(P_OUT),
        .en(CEP),
        .rst(RSTP)
        );
        
        // outputs
        assign BCOUT = B1_OUT ;
        assign M = M_OUT;
        assign CARRYOUT = CYO_OUT;
        assign CARRYOUTF = CYO_OUT ;
        assign P= P_OUT ;
        assign PCOUT = P_OUT ;
endmodule
