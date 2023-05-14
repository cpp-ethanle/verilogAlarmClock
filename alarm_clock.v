`timescale 1ns / 1ps

module alarmClock(input CLK100MHZ, SW, alarmSW, SW2, input [4:0] SWI, input SWM,
output [7:0] AN, output [6:0]C, output [1:0] musicLED, 
output [4:0] soundLED, output audioOut, aud_sd, DP);
wire outsignal1, outsignal2; 
wire[2:0] S;
wire flag, musicFlag, counterStarted;
wire[5:0] minutes, seconds, minutesL, secondsL;
wire[3:0] minuteTens, minuteOnes, secondTens, secondOnes;
wire[3:0] minuteLTens, minuteLOnes, secondLTens, secondLOnes;
wire[6:0] w0,w1,w2,w3,w4,w5,w6,w7;
slowerClkGen stageA(CLK100MHZ, 1'b0, outsignal1, outsignal2);
upcounter stageB(1'b1, outsignal2, 1'b1, S);
minuteAndSecondsCounter stageC(outsignal1, SW, minutes, seconds, counterStarted);
alarmSet stageD(SWI, minutesL, secondsL);
digitSeparator stageE(minutesL, secondsL, minuteLOnes, minuteLTens, secondLOnes, secondLTens);
digitSeparator stageF(minutes, seconds, minuteOnes, minuteTens, secondOnes, secondTens);
patternSelection stageG(w0, secondOnes);
patternSelection stageH(w1, secondTens);
patternSelection stageI(w2, minuteOnes);
patternSelection stageJ(w3, minuteTens);
patternSelection stageK(w4, secondLOnes);
patternSelection stageL(w5, secondLTens);
patternSelection stageM(w6, minuteLOnes);
patternSelection stageN(w7, minuteLTens);
mux8to1 stageO(w0,w1,w2,w3,w4,w5,w6,w7,S,AN,C,DP);
startMusic stageP(minutes, seconds, minutesL, secondsL, musicLED, musicFlag, counterStarted, flag);
SongPlayer stageQ(CLK100MHZ, SWM, alarmSW, audioOut, aud_sd, soundLED, musicFlag, flag);
endmodule


module patternSelection(output reg [6:0] pattern, input [3:0] num);
always@(num)
case(num) 
'd0:
    pattern=7'b000_0001; //0
'd1:
    pattern=7'b100_1111; //1
'd2:
    pattern=7'b001_0010; //2
'd3:
    pattern=7'b000_0110; //3
'd4:
    pattern=7'b100_1100; //4
'd5:
    pattern=7'b010_0100; //5
'd6:
    pattern=7'b010_0000; //6
'd7:
    pattern=7'b000_1111; //7
'd8:
    pattern=7'b000_0000; //8
'd9:
    pattern=7'b000_1100; //9
endcase 
endmodule


module mux8to1(w0,w1,w2,w3,w4,w5,w6,w7,S,AN,C,DP);
input [6:0] w0,w1,w2,w3,w4,w5,w6,w7;
input [2:0] S;
output reg[7:0]AN;
output reg[6:0]C;
output reg DP;
always@(S)
case(S)
3'b000:begin
C=w0;
AN=8'b1111_1110;
DP=1'b1;
end
3'b001:begin
C=w1;
AN=8'b1111_1101;
DP=1'b1;
end
3'b010:begin
C=w2;
AN=8'b1111_1011;
DP=1'b0;
end
3'b011:begin
C=w3;
AN=8'b1111_0111;
DP=1'b1;
end
3'b100:begin
C=w4;
AN=8'b1110_1111; 
DP=1'b1;
end
3'b101:begin
C=w5;
AN=8'b1101_1111;
DP=1'b1;
end
3'b110:begin
C=w6;
AN=8'b1011_1111;
DP=1'b0;
end
3'b111:begin
C=w7;
AN=8'b0111_1111;
DP=1'b1;
end
endcase
endmodule   


module minuteAndSecondsCounter(Clock,Resetn,min,sec,counterStarted);
input Clock, Resetn;
output reg counterStarted;
output reg [5:0] sec;
output reg [5:0] min;
always@(negedge Resetn, posedge Clock)
begin
    if(!Resetn) 
    begin
        counterStarted = 1'b0;
        sec = 0;
        min = 0;
    end
    else if(sec == 59) 
    begin
        sec = 0;
        min = min + 1;
    end
    else
    begin
        counterStarted = 1'b1;
        sec = sec + 1; 
    end
end
endmodule

module alarmSet(SWI,min,sec);
input [4:0] SWI;
output reg [5:0] sec;
output reg [5:0] min;
always@(SWI)
begin
case(SWI)
5'b10000: begin
min = 2;
sec = 30;
end
5'b01000: begin
min = 2;
sec = 0;
end
5'b00100: begin
min = 1;
sec = 30;
end
5'b00010: begin
min = 1;
sec = 0;
end
5'b00001: begin
min = 0;
sec = 30;
end
default: begin
min = 0;
sec = 0;
end
endcase
end
endmodule


module startMusic(input [5:0] min1, sec1, min2, sec2, output reg [1:0] LED, input musicFlag, counterStarted, output reg flag);
always@(*)begin
    if((counterStarted && musicFlag == 1) | (counterStarted && ((min1 == min2) && (sec1 == sec2))))
        begin
        LED = 2'b11;
        flag = 1'b1;
        end
    else 
        begin
        LED = 2'b00;
        flag = 1'b0;
        end
end
endmodule


module digitSeparator(min,sec,minOnes,minTens,secOnes,secTens);
input[5:0] min;
input[5:0] sec;

output [3:0] minOnes;
output [3:0] minTens;
output [3:0] secOnes;
output [3:0] secTens;

assign minTens = min/10;
assign minOnes = min%10;
assign secTens = sec/10;
assign secOnes = sec%10;

endmodule


module upcounter (Resetn, Clock, E, Q);
input Resetn, Clock, E;
output reg [2:0] Q;
always @(negedge Resetn, posedge Clock)
 if (!Resetn)
Q <= 3'b000;
else if (E)
Q <= Q + 1;
endmodule


module slowerClkGen(clk, resetSW, outsignal1, outsignal2);
    input clk;
    input resetSW;
    output reg outsignal1, outsignal2;
reg [26:0] counter,counter2;  
    always @ (posedge clk)
    begin
if (resetSW)
  begin
    counter=0;
    counter2=0;
    outsignal1=0;
    outsignal2=0;
  end
else
  begin
  counter = counter +1;
  counter2 = counter2 +1;
  if (counter == 50_000_000) //1 Hz ---> 1 sec 
        begin
        outsignal1=~outsignal1;
        counter=0;
        end
  if (counter2 == 125_000) //400 Hz ---> 1/400 sec
        begin
        outsignal2=~outsignal2;
        counter2=0;
        end
            end
                end
endmodule


module MusicSheet( input [9:0] number, 
output reg [19:0] note,//what is the max frequency  
output reg [4:0] duration);
parameter   QUARTER = 5'b00010; 
parameter HALF = 5'b00100;
parameter ONE = 2* HALF;
parameter TWO = 2* ONE;
parameter FOUR = 2* TWO;
parameter A4=113598.8,B4=101198,G4S=120357.9,E4=151662.6,C4=191109.6,C4S=180377.1,SP=1;
parameter D4=170247.4, C5S=90150.88, D5=85088.14, E5=75799.63, D5S=80309.71, C5=95514.86;
always @ (number) begin
case(number) 
0: begin note = E5; duration = QUARTER; end
1: begin note = D5S; duration = QUARTER; end
2: begin note = E5; duration = QUARTER; end
3: begin note = D5S; duration = QUARTER; end
4: begin note = E5; duration = QUARTER; end
5: begin note = B4; duration = QUARTER; end
6: begin note = D5; duration = QUARTER; end
7: begin note = C5; duration = QUARTER; end
8: begin note = A4; duration = QUARTER; end
9: begin note = SP; duration = HALF; end
10: begin note = C4; duration = QUARTER; end
11: begin note = E4; duration = QUARTER; end
12: begin note = A4; duration = QUARTER; end
13: begin note = B4; duration = QUARTER; end
14: begin note = SP; duration = HALF; end
15: begin note = E4; duration = QUARTER; end
16: begin note = G4S; duration = QUARTER; end
17: begin note = B4; duration = QUARTER; end
18: begin note = C5; duration = QUARTER; end
19: begin note = SP; duration = HALF; end
20: begin note = E4; duration = QUARTER; end 
21: begin note = E5; duration = QUARTER; end
22: begin note = D5S; duration = QUARTER; end
23: begin note = E5; duration = QUARTER; end
24: begin note = D5S; duration = QUARTER; end 
25: begin note = E5; duration = QUARTER; end
26: begin note = B4; duration = QUARTER; end 
27: begin note = D5; duration = QUARTER; end
28: begin note = C5; duration = QUARTER; end
29: begin note = A4; duration = QUARTER; end 
30: begin note = SP; duration = HALF; end
31: begin note = C4; duration = QUARTER; end 
32: begin note = E4; duration = QUARTER; end 
33: begin note = A4; duration = QUARTER; end
34: begin note = B4; duration = QUARTER; end
35: begin note = SP; duration = HALF; end 
36: begin note = E4; duration = QUARTER; end
37: begin note = C5; duration = QUARTER; end
38: begin note = B4; duration = QUARTER; end
39: begin note = A4; duration = QUARTER; end
40: begin note = SP; duration = HALF; end
default: begin note = SP; duration = FOUR; end
endcase
end
endmodule


module SongPlayer( input clock, input reset, input playSound, output reg 
audioOut, output wire aud_sd, output reg [4:0] LED, output reg musicFlag, input flag);
reg [19:0] counter;
reg [31:0] time1, noteTime;
reg [9:0] msec, number; //millisecond counter, and sequence number of musical note.
wire [4:0] note, duration;
wire [19:0] notePeriod;
parameter clockFrequency = 100_000_000; 
assign aud_sd = 1'b1;
MusicSheet  mysong(number, notePeriod, duration);

always@(playSound)
if(playSound)
    LED = 5'b11111;
else 
    LED = 5'b00000;

always @ (posedge clock) 
  begin
if(reset | ~playSound | ~flag) 
 begin 
          counter <=0;  
          time1<=0;  
          number <=0;  
          audioOut <=1;
          //LED <= 5'b00000;
          musicFlag = 0;
 end
else 
begin
//LED = 5'b11111;
musicFlag = 1;
counter <= counter + 1; 
time1<= time1+1;
if( counter >= notePeriod) 
   begin
counter <=0;  
audioOut <= ~audioOut ; 
   end //toggle audio output 
if( time1 >= noteTime) 
begin
time1 <=0;  
number <= number + 1; 
end  //play next note
 if(number == 48) begin 
 musicFlag = 0;
 number <=0; // Make the number reset at the end of the song
 end
end
  end
                  
  always @(duration) 
  noteTime = duration * clockFrequency/8;
       //number of   FPGA clock periods in one note.
endmodule

