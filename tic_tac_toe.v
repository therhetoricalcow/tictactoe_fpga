`timescale 1ns / 1ps

/* 
 * Definition: X is 1, O is 0
 */
`define X_TILE 1'b1
`define O_TILE 1'b0

/* 
 * Optional: (you may use if you want)
 * Game states 
 */
`define GAME_ST_START	4'b0000
`define GAME_ST_TURN_X 	4'b0001
`define GAME_ST_ERR_X 	4'b0010
`define GAME_ST_CHKV_X 	4'b0011
`define GAME_ST_CHKW_X 	4'b0100
`define GAME_ST_WIN_X 	4'b0101
`define GAME_ST_TURN_O 	4'b0110
`define GAME_ST_ERR_O 	4'b0111
`define GAME_ST_CHKV_O 	4'b1000
`define GAME_ST_CHKW_O 	4'b1001
`define GAME_ST_WIN_O 	4'b1010
`define GAME_ST_CATS 	4'b1011

`define one_hot_1 9'b000000001
`define one_hot_2 9'b000000010
`define one_hot_3 9'b000000100
`define one_hot_4 9'b000001000
`define one_hot_5 9'b000010000
`define one_hot_6 9'b000100000
`define one_hot_7 9'b001000000
`define one_hot_8 9'b010000000
`define one_hot_9 9'b100000000


`define ASCII_E 8'b10000000
`define ASCII_X 8'b01000000
`define ASCII_NONE 8'b00100000
`define ASCII_O 8'b00010000
`define ASCII_C 8'b00001000

  /* The grid looks like this:
   * 8 | 7 | 6
   * --|---|---
   * 5 | 4 | 3
   * --|---|---
   * 2 | 1 | 0
   */

  /* 
   * Winning combinations (treys) are the following:
   * 852, 741, 630, 876, 543, 210, 840, 642
   */
  
  /* Suggestions
   * Create a module to check for a validity of a move
   * Create modules to check for a victory in the treys
   */

module treyVictoryX(winx,occ_player);
  output winx;
  input [8:0] occ_player;
  
  assign winx = (occ_player[0] & occ_player[1] & occ_player[2])|(occ_player[5] & occ_player[4] & occ_player[3])|(occ_player[6] & occ_player[7] & occ_player[8])|(occ_player[6] & occ_player[0] & occ_player[3])|(occ_player[1] & occ_player[4] & occ_player[7])|(occ_player[5] & occ_player[8] & occ_player[2])|(occ_player[0] & occ_player[4] & occ_player[8])|(occ_player[6] & occ_player[4] & occ_player[2]);
  
endmodule
module treyVictoryO(wino,occ_square,occ_player);
  output wino;
  input [8:0] occ_square;
  input [8:0] occ_player;
  
  assign wino = (!occ_player[0] & !occ_player[1] & !occ_player[2] & (occ_square[0] & occ_square[1] & occ_square[2]))|(!occ_player[5] & !occ_player[4] & !occ_player[3] & (occ_square[5] & occ_square[4] & occ_square[3]))|(!occ_player[6] & !occ_player[7] & !occ_player[8] & (occ_square[6] & occ_square[7] & occ_square[8]))|(!occ_player[6] & !occ_player[0] & !occ_player[3] & (occ_square[0] & occ_square[3] & occ_square[6]))|(!occ_player[1] & !occ_player[4] & !occ_player[7] & (occ_square[4] & occ_square[1] & occ_square[7]))|(!occ_player[5] & !occ_player[8] & !occ_player[2] & (occ_square[5] & occ_square[8] & occ_square[2]))|(!occ_player[0] & !occ_player[4] & !occ_player[8] & (occ_square[0] & occ_square[4] & occ_square[8]))|(!occ_player[6] & !occ_player[4] & !occ_player[2] & (occ_square[6] & occ_square[4] & occ_square[2]));
endmodule

module catsGame(cats,occ_square,winx,wino);
  output reg cats;
  input [8:0] occ_square;
  input winx;
  input wino;

  always @(*)begin
    if(occ_square == 9'b111111111 && winx == 1'b0 && wino == 1'b0)begin
       cats <=1'b1;
    end else begin
       cats <= 1'b0;
    end
  end
endmodule


module tictactoe(turnX, turnO, occ_pos, occ_square, occ_player, game_st_ascii, reset, clk, flash_clk, sel_pos, buttonX, buttonO);

  output turnX;
  output turnO;
  output [8:0] occ_pos, occ_square, occ_player;
  output [7:0] game_st_ascii;

  input reset, clk, flash_clk;
  input [8:0] sel_pos;
  input buttonX, buttonO;

  /* 
   * occ_square states if there's a tile in this square or not 
   * occ_player states which type of tile is in the square 
   * game_state is the 4 bit curent state;
   * occ_pos is the board with flashing 
   */
  reg [8:0] occ_square;
  reg [8:0] occ_player;
  reg [3:0] game_state;
  reg [8:0] occ_pos;
  reg [8:0] occ_squarenext;
  reg [8:0] occ_playernext;

  reg [3:0] nx_game_state;
  reg [7:0] game_st_ascii;
  reg [7:0] ascii_next;
  reg nextX;
  reg nextO;
  reg nextV;

  reg counter;
  
  //wire valid;
  //wire cats;
  reg turnX;
  reg turnO;
  reg valid;
  integer a;
  integer b;
  integer i;
  integer j;
  
  wire winx;
  wire wino;
  wire cat;
  wire wbX;
  wire wbO;
  reg rbX = 1'b0;
  reg rbO = 1'b0;
  reg regbO = 1'b0;
  reg regbX = 1'b0;
  wire bO;
  wire bX;
  reg [8:0] r_occ_pos;
  reg trig;
  
  initial counter <= 1'b0;
  initial occ_square <= 9'b000000000;
  initial occ_player <= 9'b000000000;
  initial occ_pos <= 9'b000000000;

  
  //Modules_Implemented
  treyVictoryX treyVictoryX(winx,occ_player);
  treyVictoryO treyVictoryO(wino,occ_square,occ_player);
  catsGame catsGame(cat,occ_square,winx,wino);
  
  //validity vd(occ_square, sel_pos, valid);
  //vicX vx(occ_player, vicX);
  //vicO vo(occ_square, occ_player, vicO);
  //CatsGame cg(occ_square, occ_player, vicX, vicO, cats);

  /*
   * Registers
   *  -- game_state register is provided to get you started
   */ 
  always @(posedge rising) begin
    if(rising)begin
        game_state <= nx_game_state;
        occ_square <= occ_squarenext;
        occ_player <= occ_playernext;
        game_st_ascii <= ascii_next;
        turnX <= nextX;
        turnO <= nextO;
        valid <= nextV;
	   end
	//$display("valid changed to  %b", valid);
  end

    assign rising = (clk);
/*  always @(posedge clk)begin
    rbO <= wbO;         // Creates a Register
    rbX <= wbX;  

    if (wbO == 1'b0 && rbO == 1'b1)
    begin
      regbO <= ~regbO;     // Toggle LED output
    end
 
 if (wbX == 1'b0 && rbX == 1'b1)
    begin
      regbX <= ~regbX;     // Toggle LED output
    end
  end
  assign bO = regbO;
  assign bX = regbX;*/

always @(posedge flash_clk)begin
    if(flash_clk)begin
        if(counter)begin
            counter <= 1'b0;
        end else begin
            counter <= 1'b1;
        end
        
    end
end
 always @(*)begin
        if(game_state != `GAME_ST_WIN_X && game_state != `GAME_ST_WIN_O)begin
            if(counter)begin
                occ_pos <= occ_square;
            end else begin
                occ_pos <= occ_player;
            end
        end
    
    if(game_state == `GAME_ST_WIN_X || game_state == `GAME_ST_WIN_O)begin
    if(!flash_clk)begin
              occ_pos[8:0] = 9'b000000000;
        end
    end

        if(game_state ==`GAME_ST_WIN_X)begin
      if(flash_clk)begin
            if(occ_player[0] & occ_player[1] & occ_player[2])begin
              occ_pos[8:0] = 9'b000000111;
              
            end
            if(occ_player[5] & occ_player[4] & occ_player[3])begin
              occ_pos[8:0] = 9'b000111000;
            end
            if(occ_player[6] & occ_player[7] & occ_player[8])begin
              occ_pos[8:0] = 9'b111000000;
            end
            if(occ_player[6] & occ_player[0] & occ_player[3])begin
              occ_pos[8:0] = 9'b001001001;
            end
            if(occ_player[1] & occ_player[4] & occ_player[7])begin
              occ_pos[8:0] = 9'b010010010;
            end
            if(occ_player[5] & occ_player[8] & occ_player[2])begin
              occ_pos[8:0] = 9'b100100100;
            end
            if(occ_player[0] & occ_player[4] & occ_player[8])begin
              occ_pos[8:0] = 9'b100010001;
            end
            if(occ_player[6] & occ_player[4] & occ_player[2])begin
              occ_pos[8:0] = 9'b001010100;
            end
          end 
    end else if(game_state == `GAME_ST_WIN_O)begin
      if(flash_clk)begin
            if(!occ_player[0] & !occ_player[1] & !occ_player[2])begin
              occ_pos[8:0] = 9'b000000111;
            end
            if(!occ_player[5] & !occ_player[4] & !occ_player[3])begin
              occ_pos[8:0] = 9'b000111000;
            end
            if(!occ_player[6] & !occ_player[7] & !occ_player[8])begin
              occ_pos[8:0] = 9'b111000000;
            end
            if(!occ_player[6] & !occ_player[0] & !occ_player[3])begin
              occ_pos[8:0] = 9'b001001001;
            end
            if(!occ_player[1] & !occ_player[4] & !occ_player[7])begin
              occ_pos[8:0] = 9'b010010010;
            end
            if(!occ_player[5] & !occ_player[8] & !occ_player[2])begin
              occ_pos[8:0] = 9'b100100100;
            end
            if(!occ_player[0] & !occ_player[4] & !occ_player[8])begin
              occ_pos[8:0] = 9'b100010001;
            end
            if(!occ_player[6] & !occ_player[4] & !occ_player[2])begin
              occ_pos[8:0] = 9'b001010100;
            end
          end 

  end
        end
        
 
 //end             
  always @(posedge clk)begin
    
      if((nx_game_state == `GAME_ST_TURN_X || nx_game_state == `GAME_ST_ERR_X) && (buttonX))begin
        rbX <= 1'b1;
      end
      else begin
        rbX <= 1'b0;
      end
      
      if((nx_game_state == `GAME_ST_TURN_O || nx_game_state == `GAME_ST_ERR_O) && (buttonO))begin
        rbO <= 1'b1;
      end
      else begin
        rbO <= 1'b0;
      end
      end
      assign bO = rbO;
      assign bX = rbX;
      
  always @(posedge clk) begin
  //$write("game_state is %b, game_state);
     if (reset == 1) begin
      nx_game_state <= `GAME_ST_START;
	  nextX <= 1'b1;
	  nextO <= 1'b0;
	  nextV <= 1'b1;
	  occ_squarenext <= 9'b000000000;
	  occ_playernext <= 9'b000000000;
    end
	else begin
	//$display("game state is %d", game_state);
	//$display("nextV is %b", nextV);
	//$display("occ_square is %b", occ_square);
		case(game_state) 
		
		  `GAME_ST_START: begin
			case (reset)
			  1'b1: begin nx_game_state = `GAME_ST_START; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b0; nextV = 1'b0;end
			  1'b0: begin nx_game_state = `GAME_ST_TURN_X; ascii_next = `ASCII_NONE; nextX = 1'b1; nextO = 1'b0; nextV = 1'b0;end
			endcase
		  end
		  `GAME_ST_TURN_X: begin
		  //nextX = 1'b0; nextO = 1'b1;
			case({bX, bO})
			  2'b10: begin 
			   if (((occ_square & sel_pos) != 9'b000000000 )||( sel_pos != `one_hot_1 && sel_pos != `one_hot_2 && sel_pos != `one_hot_3 && sel_pos != `one_hot_4 && sel_pos != `one_hot_5 && sel_pos != `one_hot_6 && sel_pos != `one_hot_7 && sel_pos != `one_hot_8 && sel_pos != `one_hot_9)) begin
				   nx_game_state = `GAME_ST_CHKV_X; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b0;nextV = 1'b0;
			   end
			   else begin
				 nx_game_state = `GAME_ST_CHKV_X; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;
				end
			  end
			  2'b01: begin nx_game_state = `GAME_ST_ERR_X; ascii_next = `ASCII_E; nextX = 1'b1; nextO = 1'b0; nextV = 1'b1;end
			  2'b00, 2'b11: begin nx_game_state = `GAME_ST_TURN_X; ascii_next = `ASCII_NONE; nextX = 1'b1; nextO = 1'b0; nextV = 1'b1;end
			endcase
		  end
		  `GAME_ST_ERR_X: begin
		  //nextX = 1'b0; nextO = 1'b1;
			case({bX, bO})
			  2'b10: begin 
				if (((occ_square & sel_pos) != 9'b000000000) ||(sel_pos != `one_hot_1 && sel_pos != `one_hot_2 && sel_pos != `one_hot_3 && sel_pos != `one_hot_4 && sel_pos != `one_hot_5 && sel_pos != `one_hot_6 && sel_pos != `one_hot_7 && sel_pos != `one_hot_8 && sel_pos != `one_hot_9)) begin
				  nx_game_state = `GAME_ST_CHKV_X; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b0;nextV = 1'b0;
				end
				else begin
				  nx_game_state = `GAME_ST_CHKV_X; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;
				end
			  end
			  2'b01, 2'b00, 2'b11: begin nx_game_state = `GAME_ST_ERR_X; ascii_next = `ASCII_E; nextX = 1'b1; nextO = 1'b0; nextV = 1'b1;end
			endcase
		  end
		  `GAME_ST_CHKV_X: begin
		  //nextX = 1'b0; nextO = 1'b1;
			case(valid)
			  1'b1: begin
			    nextX = 1'b0; nextO = 1'b0; nextV = 1'b0;
				nx_game_state = `GAME_ST_CHKW_X; ascii_next = `ASCII_NONE;
				occ_squarenext = occ_square | sel_pos;
				occ_playernext = occ_player | sel_pos;
			  end
			  1'b0: begin nx_game_state = `GAME_ST_ERR_X; ascii_next = `ASCII_E; nextX = 1'b1; nextO = 1'b0; nextV = 1'b1;end
			endcase
		  end
		  `GAME_ST_CHKW_X: begin
			/*case({vicX,cats})
			  2'b10: begin nx_game_state = `GAME_ST_WIN_X; ascii_next = `ASCII_X; nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;end
			  2'b01: begin nx_game_state = `GAME_ST_CATS; ascii_next = `ASCII_C; nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;end
			  2'b00: begin nx_game_state = `GAME_ST_TURN_O; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b1; nextV = 1'b1;end
			endcase*/
			if (winx) begin
			  nx_game_state = `GAME_ST_WIN_X; ascii_next = `ASCII_X; nextX = 1'b0; nextO = 1'b0; nextV = 1'b0;
			end
			else if (occ_square == 9'b111111111) begin
			  nx_game_state = `GAME_ST_CATS; ascii_next = `ASCII_C; nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;end
     
			else
			  begin nx_game_state = `GAME_ST_TURN_O; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b1; nextV = 1'b0;
   		    end
		  end
		  `GAME_ST_WIN_X: begin
		  //nextX = 1'b0; nextO = 1'b0;
			ascii_next = `ASCII_X;
			nx_game_state = `GAME_ST_WIN_X;
			nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;
		  end
		  `GAME_ST_TURN_O: begin
		    //nextX = 1'b1; nextO = 1'b0;
			case({bO, bX})
			  2'b10: begin //$
				/*for (i = 0; i < 9; i = i + 1) begin
				  if ((occ_square[i] == 1) && (sel_pos[i] == 1)) begin
				    nextV = 1'b0;
				  end
				end*/
			   if (((occ_square & sel_pos) != 9'b000000000 ) ||( sel_pos != `one_hot_1 && sel_pos != `one_hot_2 && sel_pos != `one_hot_3 && sel_pos != `one_hot_4 && sel_pos != `one_hot_5 && sel_pos != `one_hot_6 && sel_pos != `one_hot_7 && sel_pos != `one_hot_8 && sel_pos != `one_hot_9)) begin
				  nx_game_state = `GAME_ST_CHKV_O; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b0;nextV = 1'b0;
				end
				else begin
				 nx_game_state = `GAME_ST_CHKV_O; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;
				end
			  end
			  2'b01: begin nx_game_state = `GAME_ST_ERR_O; ascii_next = `ASCII_E; nextX = 1'b0; nextO = 1'b1; nextV = 1'b1;end
			  2'b00, 2'b11: begin nx_game_state = `GAME_ST_TURN_O; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b1; nextV = 1'b1;end
			endcase
		  end
		  `GAME_ST_ERR_O: begin
		   //nextX = 1'b1; nextO = 1'b0;
			case({bO, bX})
			  2'b10: begin 
				/*for (i = 0; i < 9; i = i + 1) begin
				  if ((occ_square[i] == 1) && (sel_pos[i] == 1)) begin
				    nextV = 1'b0;
				  end
				end*/
				if (((occ_square & sel_pos) != 9'b000000000 )||( sel_pos != `one_hot_1 && sel_pos != `one_hot_2 && sel_pos != `one_hot_3 && sel_pos != `one_hot_4 && sel_pos != `one_hot_5 && sel_pos != `one_hot_6 && sel_pos != `one_hot_7 && sel_pos != `one_hot_8 && sel_pos != `one_hot_9)) begin
				  //$display("invalid is bad");
				  //$display("occ_square is %b, sel_pos is %b", occ_square, sel_pos);
				  //$display("nand is %b", occ_square ~& sel_pos);
				  nx_game_state = `GAME_ST_CHKV_O; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b0; nextV = 1'b0;
				end
				else begin
				  //$display("valid is good");
				  nx_game_state = `GAME_ST_CHKV_O; ascii_next = `ASCII_NONE; nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;
				end
			  end
			  2'b01, 2'b00, 2'b11: begin nx_game_state = `GAME_ST_ERR_O; ascii_next = `ASCII_E; nextX = 1'b0; nextO = 1'b1; end
			endcase
		  end
		  `GAME_ST_CHKV_O: begin
			//valid = 1'b1;
			/*for (i = 0; i < 9; i = i + 1) begin
			  if ((occ_square[i] == 1) && (sel_pos[i] == 1)) begin
				valid = 1'b0;
			  end
			end*/
			case(valid)
			  1'b1: begin//$
				//$display("it's good!");
			  nx_game_state = `GAME_ST_CHKW_O; ascii_next = `ASCII_NONE;
			  occ_squarenext = (occ_square | sel_pos);
			  
			    //$display("occ_squarenext is %b", occ_squarenext);
			  nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;
			  end
			  1'b0: begin nx_game_state = `GAME_ST_ERR_O; ascii_next = `ASCII_E; nextX = 1'b0; nextO = 1'b1; nextV = 1'b1;end
			endcase
		  end
		  `GAME_ST_CHKW_O: begin

			if (wino) begin
			  nx_game_state = `GAME_ST_WIN_O; ascii_next = `ASCII_O; nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;end
			else if (occ_square == 9'b111111111) begin
			  nx_game_state = `GAME_ST_CATS; ascii_next = `ASCII_C; nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;end
			else  begin
			  nx_game_state = `GAME_ST_TURN_X; ascii_next = `ASCII_NONE; nextX = 1'b1; nextO = 1'b0; nextV = 1'b1; end
		  end
		  `GAME_ST_WIN_O: begin
		    nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;
			ascii_next = `ASCII_O;
			nx_game_state = `GAME_ST_WIN_O;
		  end
		  `GAME_ST_CATS: begin
		    nextX = 1'b0; nextO = 1'b0; nextV = 1'b1;
			ascii_next = `ASCII_C;
			nx_game_state = `GAME_ST_CATS;
	      end
	    endcase
	end
  end
  
endmodule





//module tictactoe(turnX, turnO, occ_pos, occ_square, occ_player, game_st_ascii, reset, clk, flash_clk, sel_pos, buttonX, buttonO);
//  output turnX;
//  output turnO;
//  output [8:0] occ_pos, occ_square, occ_player;
//  output [7:0] game_st_ascii;

//  input reset, clk, flash_clk;
//  input [8:0] sel_pos;
//  input buttonX, buttonO;

//  /* 
//   * occ_square states if there's a tile in this square or not 
//   * occ_player states which type of tile is in the square 
//   * game_state is the 4 bit curent state;
//   * occ_pos is the board with flashing 
//   */
//  reg turnX,turnO;
//  reg [7:0] game_st_ascii;
//  reg [8:0] occ_square;
//  reg [8:0] occ_player;
//  reg [3:0] game_state;
//  reg [8:0] saved_occ_pos;
//  reg [8:0] diff_occ_pos;
//  reg counter;
//  reg [8:0] occ_pos;
//  wire winx;
//  wire wino;
//  wire cat;
//	initial counter <= 1'b1;
//  initial occ_square <= 9'b000000000;
//  initial occ_player <= 9'b000000000;
//  initial occ_pos <= 9'b000000000;
//  reg [3:0] nx_game_state;

  
//  //Modules_Implemented
//  treyVictoryX treyVictoryX(winx,occ_player);
//  treyVictoryO treyVictoryO(wino,occ_square,occ_player);
//  catsGame catsGame(cat,occ_square,winx,wino);
  
//  /*
//   * Registers
//   *  -- game_state register is provided to get you started
//   */ 
//  always @(posedge rising) begin
//    game_state <= nx_game_state;
//  end
  
//  assign rising = (clk | buttonX | buttonO);
  
//  always @(*)begin
    
//    if(game_state ==`GAME_ST_WIN_X)begin
//      if(flash_clk)begin
//            if(occ_player[0] & occ_player[1] & occ_player[2])begin
//              occ_pos[8:0] <= 9'b000000111;
              
//            end
//            if(occ_player[5] & occ_player[4] & occ_player[3])begin
//              occ_pos[8:0] <= 9'b000111000;
//            end
//            if(occ_player[6] & occ_player[7] & occ_player[8])begin
//              occ_pos[8:0] <= 9'b111000000;
//            end
//            if(occ_player[6] & occ_player[0] & occ_player[3])begin
//              occ_pos[8:0] <= 9'b001001001;
//            end
//            if(occ_player[1] & occ_player[4] & occ_player[7])begin
//              occ_pos[8:0] <= 9'b010010010;
//            end
//            if(occ_player[5] & occ_player[8] & occ_player[2])begin
//              occ_pos[8:0] <= 9'b100100100;
//            end
//            if(occ_player[0] & occ_player[4] & occ_player[8])begin
//              occ_pos[8:0] <= 9'b100010001;
//            end
//            if(occ_player[6] & occ_player[4] & occ_player[2])begin
//              occ_pos[8:0] <= 9'b001010100;
//            end
//          end else if(!flash_clk)begin
//                    if(occ_player[0] & occ_player[1] & occ_player[2])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(occ_player[5] & occ_player[4] & occ_player[3])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(occ_player[6] & occ_player[7] & occ_player[8])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(occ_player[6] & occ_player[0] & occ_player[3])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(occ_player[1] & occ_player[4] & occ_player[7])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(occ_player[5] & occ_player[8] & occ_player[2])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(occ_player[0] & occ_player[4] & occ_player[8])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(occ_player[6] & occ_player[4] & occ_player[2])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//          end
//    end else if(game_state == `GAME_ST_WIN_O)begin
//      if(flash_clk)begin
//            if(!occ_player[0] & !occ_player[1] & !occ_player[2])begin
//              occ_pos[8:0] <= 9'b000000111;
//            end
//            if(!occ_player[5] & !occ_player[4] & !occ_player[3])begin
//              occ_pos[8:0] <= 9'b000111000;
//            end
//            if(!occ_player[6] & !occ_player[7] & !occ_player[8])begin
//              occ_pos[8:0] <= 9'b111000000;
//            end
//            if(!occ_player[6] & !occ_player[0] & !occ_player[3])begin
//              occ_pos[8:0] <= 9'b001001001;
//            end
//            if(!occ_player[1] & !occ_player[4] & !occ_player[7])begin
//              occ_pos[8:0] <= 9'b010010010;
//            end
//            if(!occ_player[5] & !occ_player[8] & !occ_player[2])begin
//              occ_pos[8:0] <= 9'b100100100;
//            end
//            if(!occ_player[0] & !occ_player[4] & !occ_player[8])begin
//              occ_pos[8:0] <= 9'b100010001;
//            end
//            if(!occ_player[6] & !occ_player[4] & !occ_player[2])begin
//              occ_pos[8:0] <= 9'b001010100;
//            end
//          end else if(!flash_clk)begin
//            if(!occ_player[0] & !occ_player[1] & !occ_player[2])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(!occ_player[5] & !occ_player[4] & !occ_player[3])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(!occ_player[6] & !occ_player[7] & !occ_player[8])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(!occ_player[6] & !occ_player[0] & !occ_player[3])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(!occ_player[1] & !occ_player[4] & !occ_player[7])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(!occ_player[5] & !occ_player[8] & !occ_player[2])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(!occ_player[0] & !occ_player[4] & !occ_player[8])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//            if(!occ_player[6] & !occ_player[4] & !occ_player[2])begin
//                      occ_pos[8:0] <= 9'b000000000;
//            end
//          end
      
//    end
    
//  end
//  always @(posedge flash_clk)begin

    
//    if(game_state != `GAME_ST_WIN_X && game_state != `GAME_ST_WIN_O && counter)begin
//      //O occ_pos
//      saved_occ_pos <= (occ_square - occ_player);
//      occ_pos <= diff_occ_pos+saved_occ_pos;
//      counter <= 1'b0;
      
//    end else if (game_state != `GAME_ST_WIN_X && game_state != `GAME_ST_WIN_O && !counter)begin
      
//      saved_occ_pos <= (occ_square - occ_player);
//      occ_pos <= diff_occ_pos - saved_occ_pos;
//      counter <= 1'b1;
      
//    end
//  end
  
//  always @(game_state or buttonX or buttonO or reset) begin
    
//    if(reset)begin
//      nx_game_state <= `GAME_ST_START;
//    end
    
//    case(game_state)
//      `GAME_ST_START:
//        begin
//			occ_square <= 9'b000000000;
//			occ_player <= 9'b000000000;
//			occ_pos <= 9'b000000000;
//          game_st_ascii <= `ASCII_NONE;
//          if(!reset)begin
//            nx_game_state <= `GAME_ST_TURN_X;
//          end 
//        end
//      `GAME_ST_TURN_X:
//        begin
//          /*if buttonX is detected then set next game state to 
//         	CheckValueX, if buttonO is detected then set the next
//            game state to ERRORX. If neither are detected than set the next game
//            state 
//         */
//          game_st_ascii <= `ASCII_NONE;
//          turnX <= 1'b1;turnO <= 1'b0;
//          if(buttonX)begin
//              game_state <= `GAME_ST_CHKV_X;
//          end else if(buttonO)begin
//              nx_game_state <= `GAME_ST_ERR_X;
//          end else begin
//              nx_game_state <= `GAME_ST_TURN_X;
//          end
//        end
//      `GAME_ST_ERR_X:
//        begin
//          /*If button X is detected then set next game state to check for value
//          else set the next game state to error x
//          */
//          game_st_ascii <= `ASCII_E;
//          turnX <= 1'b1;turnO <= 1'b0;
//          if(buttonX)begin
//            nx_game_state <= `GAME_ST_CHKV_X;
//          end else begin
//              nx_game_state <= `GAME_ST_ERR_X;
//          end
//        end
//        `GAME_ST_CHKV_X:
//		begin
//          /*
//          	if the sel_pos
//          */
//          game_st_ascii <= `ASCII_NONE;
//          if((sel_pos & occ_square) != 9'b000000000)begin
//            //notValid
//            game_state <= `GAME_ST_ERR_X;

//          end else if(buttonX)begin
//          //Valid
//            occ_square = occ_square + sel_pos;
//            occ_player = occ_player + sel_pos;
//            occ_pos = occ_pos + sel_pos;
//            diff_occ_pos <= occ_pos;
//            game_state <= `GAME_ST_CHKW_X;
//        end
//        end
//      `GAME_ST_CHKW_X:
//        begin
//            game_st_ascii <= `ASCII_NONE;
//          if(winx)begin
//            game_state <= `GAME_ST_WIN_X;
//          end else if(cat)begin
//            game_state <= `GAME_ST_CATS;
//          end else if(!winx)begin
//            nx_game_state <= `GAME_ST_TURN_O;
//          end
//        end
//      `GAME_ST_WIN_X:
//        begin
//          game_st_ascii <= `ASCII_X;
//          nx_game_state <= `GAME_ST_WIN_X;

          
//        end
//      `GAME_ST_TURN_O:
//        begin
//          game_st_ascii <= `ASCII_NONE;
//          turnX <= 1'b0;turnO <= 1'b1;
//        if(buttonO)begin
//              game_state <= `GAME_ST_CHKV_O;
//        end else if(buttonX)begin
//              nx_game_state <= `GAME_ST_ERR_O;
//          end else begin
//              nx_game_state <= `GAME_ST_TURN_O;
//          end
//        end
//      `GAME_ST_ERR_O:
//        begin
//          game_st_ascii <= `ASCII_E;
//          turnX <= 1'b0;turnO <= 1'b1;
//        if(buttonO)begin
//            nx_game_state <= `GAME_ST_CHKV_O;
//          end else begin
//            nx_game_state <= `GAME_ST_ERR_O;
//          end
//        end
//      `GAME_ST_CHKV_O:
//        begin
//          game_st_ascii <= `ASCII_NONE;
//          if((sel_pos & occ_square) != 9'b000000000)begin
//            //notValid
//            game_state <= `GAME_ST_ERR_O;
//          end else if(buttonO)begin
//            //Valid
//          occ_square = (occ_square + sel_pos);
//          game_state <= `GAME_ST_CHKW_O;
//      end
//        end
//      `GAME_ST_CHKW_O:
//          begin
//          game_st_ascii <= `ASCII_NONE;
//            if(wino)begin
//            game_state <= `GAME_ST_WIN_O;
//          end else if(cat)begin
//            game_state <= `GAME_ST_CATS;
//          end else if(!wino)begin
//            nx_game_state <= `GAME_ST_TURN_X;
//          end
//          end
//      `GAME_ST_WIN_O:
//        begin
//          game_st_ascii <= `ASCII_O;
//          nx_game_state <= `GAME_ST_WIN_O;

          
//        end
//      `GAME_ST_CATS:
//          begin
//          game_st_ascii <= `ASCII_C;
//          nx_game_state <= `GAME_ST_CATS;
//          end
//    endcase
//  end
//endmodule











module clock_div(
    input clk,
    input rst,
    input [28:0] speed, // = 100MHz/(2*desired_clock_frequency)
    output reg new_clk
    );
 
    
    // Count value that counts to define_speed
    reg [27:0] count;
    
    // Run on the positive edge of the clk and rst signals
    always @ (posedge(clk),posedge(rst))
    begin
        // When rst is high set count and new_clk to 0
        if (rst == 1'b1)
        begin 
            count = 28'b0;   
            new_clk = 1'b0;            
        end
        // When the count has reached the constant
        // reset count and toggle the output clock
        else if (count == speed)
        begin
            count = 28'b0;
            new_clk = ~new_clk;
        end
        // increment the clock and keep the output clock
        // the same when the constant hasn't been reached        
        else
        begin
            count = count + 1'b1;
            new_clk = new_clk;
        end
    end
endmodule

module Charlieplexer(
   input clk,
   input [35:0] led_array_state,
   output reg [5:0] row,
   output reg [5:0] col,
   output reg emit 
   );
// TODO: write the Charlieplexer state machine (Design Assignment 2)

reg [5:0] i;

always @(posedge(clk))
begin
    if(i >= 36) begin
        i = 0;
    end
    
    if(i <= 5)
    begin
        row[5:0] = 6'b000001;    
    end 
    else if(i >=6 && i <= 11)
    begin
        row[5:0] = 6'b000010;
    end 
    else if(i>=12 && i <=17)
    begin
        row[5:0] = 6'b000100;
    end 
    else if(i>=18 && i <=23)
    begin 
        row[5:0] = 6'b001000;
    end 
    else if(i>=23 && i <=29)
    begin
        row[5:0] = 6'b010000;
    end 
    else if(i>=30) 
    begin
        row[5:0] = 6'b100000;
    end
    
    if(i == 6 || i == 0 || i == 12 ||i == 18 || i == 24 || i == 30) 
    begin
        col[5:0] = 6'b000001;
    end
    else if(i == 7 || i == 1 || i == 13 ||i == 19 || i == 25 || i == 31) 
    begin
        col[5:0] = 6'b000010;
    end
    if(i == 8 || i == 2 || i == 14 ||i == 20 || i == 26 || i == 32) 
    begin
        col[5:0] = 6'b000100;
    end
    if(i == 9 || i == 3 || i == 15 ||i == 21 || i == 27 || i == 33) 
    begin
        col[5:0] = 6'b001000;
    end
    if(i == 10 || i == 4 || i == 16 ||i == 22 || i == 28 || i == 34) 
    begin
        col[5:0] = 6'b010000;
    end
    if(i == 11 || i == 5 || i == 17 ||i == 23 || i == 29 || i == 35) 
    begin
        col[5:0] = 6'b100000;
    end
    
    if(led_array_state[i])
    begin
        emit = 1'b1;    
    end else 
    begin
        emit = 1'b0;
    end

    i = i+1;
    
end


endmodule

module buffer_translator(

    input [5:0] row,
    input [5:0] col,
    input emit,
    output reg [6:0] en,
    output reg [6:0] ctrl
);

always @ (*)
begin

if(emit == 1'b1)begin
    en[0] = row[0]|(col[0]&(row[1]|row[2]|row[3]|row[4]|row[5]));
    en[1] = (col[0]&row[0])|row[1]|(col[1]&(row[2]|row[3]|row[4]|row[5]));
    en[2] = (col[1]&(row[0]|row[1]))|row[2]|(col[2]&(row[3]|row[4]|row[5]));
    en[3] = (col[2]&(row[0]|row[1]|row[2]))|row[3]|(col[3]&(row[4]|row[5]));
    en[4] = (col[3]&(row[0]|row[1]|row[2]|row[3]))|row[4]|(col[4]&row[5]);
    en[5] = (col[4]&(row[0]|row[1]|row[2]|row[3]|row[4]))|row[5];
    en[6] = (col[5]&(row[0]|row[1]|row[2]|row[3]|row[4]|row[5]));
    
    ctrl[0] = ~row[0];
    ctrl[1] = ~row[1];
    ctrl[2] = ~row[2];
    ctrl[3] = ~row[3];
    ctrl[4] = ~row[4];
    ctrl[5] = ~row[5];
    ctrl[6] = col[5];
    end
 else begin
    en[6:0] = 7'b0000000;
    ctrl[6:0] = 7'b0000000; 
end
end

// TODO: translate row and col into en and ctrl as described in Design Assignment 2
// Examples:

// Example 1: Light Col 0 in Row 0
//    Inputs:
//       row  [5:0] = 6'b000001
//       col  [5:0] = 6'b000001
//       emit       = 1'b1
//    Outputs:
//       en   [6:0] = 7'b0000011
//       ctrl [6:0] = 7'b0000010


// Example 2: Light no LEDs in Row 0
//    Inputs:
//       row  [5:0] = 6'b000001
//       col  [5:0] = 6'b000001
//       emit       = 1'b0
//    Outputs:
//       en   [6:0] = 7'b0000000
//       ctrl [6:0] = 7'b0000000

// Example 3: Light Col 1 in Row 4
//    Inputs:
//       row  [5:0] = 6'b010000
//       col  [5:0] = 6'b000010
//       emit       = 1'b1
//    Outputs:
//       en   [6:0] = 7'b0010010  
//       ctrl [6:0] = 7'b0000010

// Example 4: Light no LEDs in Row 4
//    Inputs:
//       row  [5:0] = 6'b010000
//       col  [5:0] = 6'b000010
//       emit       = 1'b0
//    Outputs:
//       en   [6:0] = 7'b0000000  
//       ctrl [6:0] = 7'b0000000

// Example 5: Light Col 5 in Row 4
//    Inputs:
//       row  [5:0] = 6'b010000
//       col  [5:0] = 6'b100000
//       emit       = 1'b1
//    Outputs:
//       en   [6:0] = 7'b1010000  
//       ctrl [6:0] = 7'b1000000

endmodule



module LED_Driver(
    input clk,
    input [8:0] sw,
    input btnC,
    input btnU,
    input btnD,
    output [15:0] led,
    output reg [6:0] seg,
    output reg [7:0] JA,
    output reg [3:0] an
    );
    
    wire sm_clk;
    wire tester_clk;
    reg [35:0] led_state;
    clock_div clock_Div(
    .clk(clk),
    .rst(btnC),
    .speed(28'd50000000),
    .new_clk(tester_clk)
    );
    
    clock_div clock_Div2(
    .clk(clk),
    .rst(btnC),
//    .speed(28'd2500),
    .speed(28'd2500),
    .new_clk(sm_clk)
    );
    wire x_turn;
    wire o_turn; 
    reg [35:0] grid_state; //1 for LED's that are on (5:0 is row 0 LEDs 5:0, etc.)
    wire [8:0] occ_position;
    wire [8:0] occ_square;
    wire [8:0] occ_player;
    wire [7:0] game_st_ascii;
    
    wire [5:0] arr_row; //addressing wires
    wire [5:0] arr_col;
    wire led_emit; //LED emit control signal

    wire [6:0] buffer_en;  //tristate buffer control signals
    wire [6:0] buffer_ctrl;
   
   
   
    tictactoe game(
    .turnX(x_turn),
    .turnO(o_turn),
    .occ_pos(occ_position),
    .occ_square(occ_square),
    .occ_player(occ_player),
    .game_st_ascii(game_st_ascii),
    .reset(btnC),
    .clk(clk),
    .flash_clk(tester_clk),
    .sel_pos(sw),
    .buttonX(btnU),
    .buttonO(btnD)
    );
    Charlieplexer Charlie(
    .clk(sm_clk),
    .led_array_state(grid_state),
    .row(arr_row),
    .col(arr_col),
    .emit(led_emit)
    );

    buffer_translator BT(
    .row(arr_row),
    .col(arr_col),
    .emit(led_emit),
    .en(buffer_en),
    .ctrl(buffer_ctrl)
    );
    
    
    //CL
    assign led[8:0] = (sw|occ_position);
    assign led[15] = x_turn;
    assign led[14] = o_turn;

    always @ (*)
    begin
    
    if(occ_position[8])begin
        if(occ_player[8])begin
            led_state[35:34] <= 2'b11;
            led_state[29:28] <= 2'b11;
        end else begin
            led_state[35:34] <= 2'b00;
            led_state[29:28] <= 2'b11;
        end 
        
    end else begin
            led_state[35:34] <= 2'b00;
            led_state[29:28] <= 2'b00;
    end
    if(occ_position[7])begin
        if(occ_player[7])begin
            led_state[33:32] <= 2'b11;
            led_state[27:26] <= 2'b11;
        end else begin
            led_state[33:32] <= 2'b00;
            led_state[27:26] <= 2'b11;
        end
        
    end else begin
            led_state[33:32] <= 2'b00;
            led_state[27:26] <= 2'b00;
    end
    if(occ_position[6])begin
        if(occ_player[6])begin
            led_state[31:30] <= 2'b11;
            led_state[25:24] <= 2'b11;
        end else begin
            led_state[31:30] <= 2'b00;
            led_state[25:24] <= 2'b11;
        end 
        
    end else begin
            led_state[31:30] <= 2'b00;
            led_state[25:24] <= 2'b00;
        end
    if(occ_position[5])begin
        if(occ_player[5])begin
            led_state[23:22] <= 2'b11;
            led_state[17:16] <= 2'b11;
        end else begin
            led_state[23:22] <= 2'b00;
            led_state[17:16] <= 2'b11;
        end 
        
    end else begin
            led_state[23:22] <= 2'b00;
            led_state[17:16] <= 2'b00;
        end
    if(occ_position[4])begin
        if(occ_player[4])begin
            led_state[21:20] <= 2'b11;
            led_state[15:14] <= 2'b11;
        end else begin
            led_state[21:20] <= 2'b00;
            led_state[15:14] <= 2'b11;
        end 
        
    end else begin
            led_state[21:20] <= 2'b00;
            led_state[15:14] <= 2'b00;
        end
    if(occ_position[3])begin
        if(occ_player[3])begin
            led_state[19:18] <= 2'b11;
            led_state[13:12] <= 2'b11;
        end else begin
            led_state[19:18] <= 2'b00;
            led_state[13:12] <= 2'b11;
        end 
        
    end else begin
            led_state[19:18] <= 2'b00;
            led_state[13:12] <= 2'b00;
        end 
    if(occ_position[2])begin
        if(occ_player[2])begin
                        led_state[11:10] <= 2'b11;
            led_state[5:4] <= 2'b11;
        end else begin
                        led_state[11:10] <= 2'b00;
            led_state[5:4] <= 2'b11;
        end 
        
    end else begin
            led_state[11:10] <= 2'b00;
            led_state[5:4] <= 2'b00;
        end
    if(occ_position[1])begin
        if(occ_player[1])begin
            led_state[9:8] <= 2'b11;
            led_state[3:2] <= 2'b11;
        end else begin
            led_state[9:8] <= 2'b00;
            led_state[3:2] <= 2'b11;
        end 
        
    end else begin
            led_state[9:8] <= 2'b00;
            led_state[3:2] <= 2'b00;
        end       
    if(occ_position[0])begin
        if(occ_player[0])begin
            led_state[7:6] <= 2'b11;
            led_state[1:0] <= 2'b11; 
        end else begin
            led_state[7:6] <= 2'b00;
            led_state[1:0] <= 2'b11; 
        end 
        
    end else begin
            led_state[7:6] <= 2'b00;
            led_state[1:0] <= 2'b00;
        end
    case(game_st_ascii)
            `ASCII_E:
            begin
                seg <= 7'b0000110;
                an <= 4'b1110;
            end
            `ASCII_NONE:
            begin
                seg <= 7'b0101011;
                
                an <= 4'b1110;
            end
            `ASCII_O:
            begin
                seg <= 7'b1000000;
                
                an <= 4'b1110;
            end
            `ASCII_X:
            begin
                seg <= 7'b0001001;
                an <= 4'b1110;
            end
            default:
            begin
                seg <= 7'b1111111;
                an <=4'b1111;
            end
    endcase
    
    JA[7] = 1'bZ;
        if(!buffer_en[0])begin
    
        JA[0] = 1'bZ;
        end else begin
            if(buffer_ctrl[0])begin
            JA[0] = 1'b1;
            end else begin
            JA[0] = 1'b0;
            end
        end
        if(!buffer_en[1])begin
    
        JA[1] = 1'bZ;
        end else begin
            if(buffer_ctrl[1])begin
            JA[1] = 1'b1;
            end else begin
            JA[1] = 1'b0;
            end
        end
        if(!buffer_en[2])begin
    
        JA[2] = 1'bZ;
        end else begin
            if(buffer_ctrl[2])begin
            JA[2] = 1'b1;
            end else begin
            JA[2] = 1'b0;
            end
        end
        if(!buffer_en[3])begin
    
        JA[3] = 1'bZ;
        end else begin
            if(buffer_ctrl[3])begin
            JA[3] = 1'b1;
            end else begin
            JA[3] = 1'b0;
            end
        end
        if(!buffer_en[4])begin
    
        JA[4] = 1'bZ;
        end else begin
            if(buffer_ctrl[4])begin
            JA[4] = 1'b1;
            end else begin
            JA[4] = 1'b0;
            end
        end
        if(!buffer_en[5])begin
    
        JA[5] = 1'bZ;
        end else begin
            if(buffer_ctrl[5])begin
            JA[5] = 1'b1;
            end else begin
            JA[5] = 1'b0;
            end
        end
        if(!buffer_en[6])begin
    
        JA[6] = 1'bZ;
        end else begin
            if(buffer_ctrl[6])begin
            JA[6] = 1'b1;
            end else begin
            JA[6] = 1'b0;
            end
        end

        end
    
   
       //TODO: Use buffer_en and buffer_ctrl to drive JA[7:0] 
       
// Example 1: Light Col 0 in Row 0
//    Inputs:
//       en   [6:0] =  7'b0000011
//       ctrl [6:0] =  7'b0000010
//    Outputs:
//       JA   [7:0] = 8'bZZZZZZ10

// Example 2: Light no LEDs in Row 0
//    Inputs:
//       en   [6:0] =  7'b0000000
//       ctrl [6:0] =  7'b0000000
//    Outputs:
//       JA   [7:0] = 8'bZZZZZZZZ

// Example 3: Light Col 1 in Row 4
//    Inputs:
//       en   [6:0] =  7'b0010010  
//       ctrl [6:0] =  7'b0000010
//    Outputs:
//       JA   [7:0] = 8'bZZZ0ZZ1Z

// Example 4: Light no LEDs in Row 4
//    Inputs:
//       en   [6:0] =  7'b0000000  
//       ctrl [6:0] =  7'b0000000
//    Outputs:
//       JA   [7:0] = 8'bZZZZZZZZ

// Example 5: Light Col 5 in Row 4
//    Inputs:
//       en   [6:0] =  7'b1010000  
//       ctrl [6:0] =  7'b1000000
//    Outputs:
//       JA   [7:0] = 8'bZ1Z0ZZZZ

 
    //TESTER BLOCK, DO NOT MODIFY
    always @ (*)
    begin
        grid_state <= led_state;

    end

    
endmodule


