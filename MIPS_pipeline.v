`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  
// 
// 
// Create Date: 19.03.2026 11:03:07
// Design Name: Juriel Pereira
// Module Name: MIPS_pipeline
// Project Name: MIPS Processor 
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


module MIPS_pipeline(
    input clk1,             //Two-phase clock
    input clk2
    );
 
 //1.Fetch stage  
 reg [31:0] PC, IF_ID_NPC, IF_ID_IR; 
 
 //2.Decode stage    
 reg [31:0] ID_EX_A, ID_EX_B, ID_EX_NPC, ID_EX_IR, ID_EX_IMM;
 reg [2:0] ID_EX_TYPE; 
 
 //3.Execute stage 
 reg [31:0] EX_MEM_ALUOUT, EX_MEM_B, EX_MEM_IR ;  
 reg EX_MEM_COND;
 reg [2:0] EX_MEM_TYPE;
  
 // 4.Memory stage
 reg [31:0] MEM_WB_IR,MEM_WB_ALUOUT,MEM_WB_LMB;
 reg [2:0] MEM_WB_TYPE; 
  
 //modeling memroy and reg bank
 reg [31:0] MEM[0:1023]; // 1024 x 32 memory
 reg [31:0] REG[0:31];  // 32 x 32register bank 
 
 // set after HLT instruction is completed (WB stage)
 reg HALTED;
 
 //Required to disable instruction after branch 
 reg TAKEN_BRANCH;

//Opcodes  
parameter   ADD =   6'b000000,
            SUB =   6'b000001,
            AND =   6'b000010,
            OR  =   6'b000011,
            SLT =   6'b000100,
            MUL =   6'b000101,
            HLT =   6'b111111, 
            LW  =   6'b001000,
            SW  =   6'b001001,
            ADI =   6'b001010,
            SUBI=   6'b001011,
            SLTI=   6'b001100,
            BNEQZ=  6'b001101,
            BEQZ=   6'b001110;
 
 //Addressing types
 parameter  RR_ALU  =   3'b000,
            RI_ALU  =   3'b001,
            LOAD    =   3'b010,
            STORE   =   3'b011,
            BRANCH  =   3'b100,
            HALT    =   3'b101;    
 
 
//1.IF Pipeline
always @(posedge clk1)
if(HALTED == 0)
begin 
    //Branch True  
    if(((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_COND == 1)) ||
        ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_COND == 0)))
        begin
            IF_ID_IR        <=  MEM[EX_MEM_ALUOUT];  //Jump to branch addr. and load IR with branch addr. data
            TAKEN_BRANCH    <=  1'b1;
            IF_ID_NPC       <=  EX_MEM_ALUOUT + 1;
            PC              <=  EX_MEM_ALUOUT + 1;      
        end
    //No Branch
    else
        begin
            IF_ID_IR        <= MEM[PC];
            IF_ID_NPC       <= PC + 1;
            PC              <= PC + 1;
        end
end

//ID Pipeline
always @(posedge clk2)     
if(HALTED == 0)
begin

ID_EX_NPC   <=  IF_ID_NPC;      //forwarding PC    
ID_EX_IR    <=  IF_ID_IR;       // forwarding IR

if (IF_ID_IR[25:21] == 5'b00000)    //rs
    ID_EX_A     <=  0;              //assign direct value donot acces the reg. bank
else 
    ID_EX_A     <=  REG[IF_ID_IR[25:21]];

if (IF_ID_IR[20:16] == 5'b00000)   //rt
    ID_EX_B     <=  0;
else
    ID_EX_B     <=  REG[IF_ID_IR[20:16]];

ID_EX_IMM   <=  {{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}}; //immediate data

case(IF_ID_IR[31:26])           //check opcode
    ADD,SUB,AND,OR,SLT,MUL : ID_EX_TYPE <= RR_ALU;
    ADI,SUBI,SLTI          : ID_EX_TYPE <= RI_ALU;
    LW                     : ID_EX_TYPE <= LOAD;
    SW                     : ID_EX_TYPE <= STORE;
    BEQZ,BNEQZ             : ID_EX_TYPE <= BRANCH;
    HALT                   : ID_EX_TYPE <= HALT;
    default                : ID_EX_TYPE <= HALT;
endcase    
end


//IEXE
always @(posedge clk1)
if (HALTED == 0)
begin
    EX_MEM_TYPE     <= ID_EX_TYPE;
    EX_MEM_IR       <= ID_EX_IR;
    TAKEN_BRANCH    <= 0;
    
    case(ID_EX_TYPE)
        RR_ALU      :  begin
                        case(ID_EX_IR[31:26])
                                ADD : EX_MEM_ALUOUT <=  ID_EX_A + ID_EX_B;      
                                SUB : EX_MEM_ALUOUT <=  ID_EX_A - ID_EX_B;   
                                AND : EX_MEM_ALUOUT <=  ID_EX_A & ID_EX_B;
                                OR  : EX_MEM_ALUOUT <=  ID_EX_A | ID_EX_B;
                                SLT : EX_MEM_ALUOUT <=  ID_EX_A < ID_EX_B;
                                MUL : EX_MEM_ALUOUT <=  ID_EX_A * ID_EX_B;
                                default : EX_MEM_ALUOUT <=  32'hxxxxxxxx;
                        endcase
                       end
                       
       RI_ALU       :  begin
                        case(ID_EX_IR[31:26])
                                ADI     : EX_MEM_ALUOUT <=  ID_EX_A + ID_EX_IMM;        
                                SUBI    : EX_MEM_ALUOUT <=  ID_EX_A - ID_EX_IMM; 
                                SLTI    : EX_MEM_ALUOUT <=  ID_EX_A < ID_EX_IMM;
                                default : EX_MEM_ALUOUT <=  32'hxxxxxxxx;
                                 
                        endcase
                       end
      
      LOAD,STORE           : begin 
                                EX_MEM_ALUOUT <=  ID_EX_A + ID_EX_IMM;
                                EX_MEM_B      <=  ID_EX_B;
                             end 
                         
      BRANCH        : begin 
                        EX_MEM_ALUOUT <=  ID_EX_NPC + ID_EX_IMM;
                        EX_MEM_COND   <=  (ID_EX_A == 0); 
                      end  
      default: ;
      endcase              
end                   
                       
//MEM
always @(posedge clk2)
if(HALTED == 0)
begin
    MEM_WB_IR   <=  EX_MEM_IR;
    MEM_WB_TYPE     <=  EX_MEM_TYPE ;
    
    case(EX_MEM_TYPE)
        RR_ALU,RI_ALU :   MEM_WB_ALUOUT <=  EX_MEM_ALUOUT;      //forwarding 
        LOAD          :   MEM_WB_LMB    <=  MEM[EX_MEM_ALUOUT];
        STORE         :   MEM[EX_MEM_ALUOUT]    <=  EX_MEM_B;
        HALT          :   HALTED <= 1'b1; 
        default: ;
        endcase                    
end

//WB                      
always @(posedge clk1)
begin
    case (MEM_WB_TYPE)
            RR_ALU : REG[MEM_WB_IR[15:11]] <= MEM_WB_ALUOUT;
            RI_ALU : REG[MEM_WB_IR[20:16]] <= MEM_WB_ALUOUT;
            LOAD   : REG[MEM_WB_IR[20:16]] <= MEM_WB_LMB;
            default: ;
    endcase
end

endmodule
