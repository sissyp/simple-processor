LIBRARY ieee; 
USE ieee.std_logic_1164.all; 
USE ieee.std_logic_signed.all; 
-- The main entity proc will help us implement a simple processor
ENTITY proc IS 
    PORT ( DIN : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
           Resetn, Clock, Run : IN STD_LOGIC; 
		     Done : BUFFER STD_LOGIC; 
           BusWires : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0));
END proc; 
--we declare 3 components: upcount, dec3to8 and regn
--the first component implements an upcounter
--the second component implements a 3 to 8 decoder 
--the third component implements a 16-bits register. 
ARCHITECTURE Behavior OF proc IS 
	COMPONENT upcount 
			PORT ( Clear, Clock : IN STD_LOGIC; 
				   Q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)); 
		END COMPONENT;
		COMPONENT dec3to8 
			PORT ( W : IN STD_LOGIC_VECTOR(2 DOWNTO 0); 
				   En : IN STD_LOGIC; 
				   Y : OUT STD_LOGIC_VECTOR(0 TO 7)); 
		END COMPONENT;	 
		COMPONENT regn
			GENERIC (n : INTEGER := 16); 
			PORT ( R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0); 
				   Rin, Clock : IN STD_LOGIC; 
				   Q : BUFFER STD_LOGIC_VECTOR(n-1 DOWNTO 0)); 
		END COMPONENT;  
--we declare all the signals we are going to use for the simple processor
--S is the bus selector
		SIGNAL Rin,Rout : STD_LOGIC_VECTOR(0 TO 7);
		SIGNAL ALUout		:	STD_LOGIC_VECTOR(15 DOWNTO 0);
		SIGNAL Clear, High, IRin, DINout, Ain, Gin, Gout: STD_LOGIC;
		SIGNAL ALUop : STD_LOGIC_VECTOR(2 DOWNTO 0);
		SIGNAL Tstep_Q : STD_LOGIC_VECTOR(1 DOWNTO 0);
		SIGNAL I : STD_LOGIC_VECTOR(2 DOWNTO 0);
		SIGNAL Xreg,Yreg: STD_LOGIC_VECTOR(0 TO 7);
		SIGNAL R0,R1,R2,R3,R4,R5,R6,R7, A, G : STD_LOGIC_VECTOR(15 DOWNTO 0);
		SIGNAL IR: STD_LOGIC_VECTOR(1 TO 9);
		SIGNAL S: STD_LOGIC_VECTOR (1 TO 10);
BEGIN 
	  High <= '1'; 
	  Clear <= NOT (Resetn) OR Done OR (NOT(Run) AND NOT(Tstep_Q(1)) AND NOT (Tstep_Q(0)));
	  Tstep: upcount PORT MAP (Clear, Clock, Tstep_Q);
	  I <= IR(1 TO 3);
	  decX: dec3to8 PORT MAP (IR(4 TO 6), High, Xreg);
	  decY: dec3to8 PORT MAP (IR(7 TO 9), High, Yreg);
	  
		-- Instruction Table
		--  000: mv			Rx,Ry
		--  001: mvi		Rx,#D
		--  010: and        Rx,Ry	
		--  011: or         Rx,Ry	
		--  100: add		Rx,Ry				: Rx <- [Rx] + [Ry]
		--  101: sub		Rx,Ry				: Rx <- [Rx] - [Ry]
		--  110: xor        Rx,Ry	
		--  111: not        Rx,Ry
		-- 	OPCODE format: III XXX YYY, where 
		-- 	III = instruction, XXX = Rx, and YYY = Ry. For mvi,
		-- 	a second word of data is loaded from DIN

	  controlsignals: PROCESS (Tstep_Q, I, Xreg, Yreg) 
	  BEGIN 
--we initialize the values of Done,Ain,Gin,Gout,ALUop,IRin,DINout,Rin and Rout 
	   Done <= '0'; Ain <= '0'; Gin  <= '0';
		Gout <= '0';ALUop <= "000";IRin <='0';
		DINout <='0';Rin <="00000000"; Rout <="00000000";
		CASE Tstep_Q IS 
		  WHEN "00" =>  --we store DIN in IR as long as Tstep_Q = 0 
			IRin <= '1'; 
		  WHEN "01" =>  --we define signals intime step T1 
			CASE I IS 
				WHEN "000"=>--mv
					Rout<=Yreg;
					Rin<=Xreg;
					Done<='1';
				WHEN "001"=>--mvi
					DINout<='1';
					Rin<=Xreg;
					Done<='1';
				WHEN "100"=>--add
					Rout<=Xreg;
					Ain<='1';
				WHEN "101"=>--sub
					Rout<=Xreg;
					Ain<='1';
				WHEN OTHERS =>--and,or,xor,nor
					Rout <= Xreg;
					Ain <= '1';
			END CASE; 
		  WHEN "10" => --we define signals intime step T2 
			CASE I IS 
				WHEN "010"=>--and
					Rout<= Yreg;
					ALUop<="010";
					Gin<='1';
				WHEN "011" =>--or
					Rout<= Yreg;
					ALUop<="011";
					Gin<='1';
				WHEN "100"=>--add
					Rout<=Yreg;
					ALUop<="100";
					Gin<='1';
				WHEN "101"=>--sub
					Rout<=Yreg;
					ALUop<="101";
					Gin<='1';
				WHEN "110"=>--xor
					Rout<=Yreg;
					ALUop<="110";
					Gin<='1';
				WHEN "111"=>--nor
					Rout<=Yreg;
					ALUop<="111";
					Gin<='1';
				WHEN OTHERS=>
			END CASE; 
		  WHEN "11" =>--we define signals intime step T3 
			CASE I IS 
				WHEN "010"=>--and
					Gout<='1';
					Rin<=Xreg;
					Done<='1';
				WHEN "011" =>--or
					Gout<='1';
					Rin<=Xreg;
					Done<='1';
				WHEN "100" =>--add
					Gout<='1';
					Rin<=Xreg;
					Done<='1';
				WHEN "101" =>--sub
					Gout<='1';
					Rin<=Xreg;
					Done<='1';
				WHEN "110" =>--xor
					Gout<='1';
					Rin<=Xreg;
					Done<='1';
				WHEN "111" =>--nor
					Gout<='1';
					Rin<=Xreg;
					Done<='1';
				WHEN OTHERS=>
			END CASE; 
		END CASE; 
	  END PROCESS;
--We create the registers we will be using for our simple processor. 
	  reg_0: regn PORT MAP ( BusWires, Rin(0), Clock, R0 ); 
	  reg_1: regn PORT MAP ( BusWires, Rin(1), Clock, R1 ) ;
	  reg_2: regn PORT MAP ( BusWires, Rin(2), Clock, R2 ) ;
	  reg_3: regn PORT MAP ( BusWires, Rin(3), Clock, R3 ) ;
	  reg_4: regn PORT MAP ( BusWires, Rin(4), Clock, R4 ) ;
	  reg_5: regn PORT MAP ( BusWires, Rin(5), Clock, R5 ) ;
	  reg_6: regn PORT MAP ( BusWires, Rin(6), Clock, R6 ) ;
	  reg_7: regn PORT MAP ( BusWires, Rin(7), Clock, R7 ) ; 
	  reg_A: regn PORT MAP ( BusWires, Ain, Clock, A ) ;
	  reg_IR: regn GENERIC MAP (n => 9) PORT MAP (DIN(15 DOWNTO 7), IRin, Clock, IR);
--This is our simple processor's ALU.
--Based on the given table we use ALUop to calculate each of the following functionc: AND,OR, ADD, SUB, XOR AND NOR.	  
	 alu: Process(ALUop, A, BusWires)
    BEGIN
        case AlUop Is
         when "010" =>
              AlUout <= A and BusWires;
         when "011" =>
              ALUout <=  A or BusWires;
         when "100" =>
              ALUout <= A + BusWires;
         when "101" =>
              ALUout <= A - BusWires;
		   when "110" =>
              ALUout <= A xor BusWires;
         when "111" =>
              ALUout <= A nor BusWires;
         when others =>
              ALUout <= "0000000000000000";
       End Case;
  END PROCESS;
  
  reg_G: regn PORT MAP(ALUout,Gin,Clock,G);
  S<= Rout & Gout & DINout;
--Below we create the bus.
  mux: PROCESS (S, R0,R1,R2,R3,R4,R5,R6,R7,G,DIN)
  BEGIN
		IF S="1000000000" THEN
			BusWires<=R0;
		ELSIF S="0100000000" THEN
			BusWires<=R1;
		ELSIF S="0010000000" THEN
			BusWires<=R2;
		ELSIF S="0001000000" THEN
			BusWires<=R3;
		ELSIF S="0000100000" THEN
			BusWires<=R4;
		ELSIF S="0000010000" THEN
			BusWires<=R5;
		ELSIF S="0000001000" THEN
			BusWires<=R6;
		ELSIF S="0000000100" THEN
			BusWires<=R7;
		ELSIF S="0000000010" THEN
			BusWires<=G;
		ELSE 
			BusWires<=DIN;
		END IF;
	END PROCESS;
END Behavior;

LIBRARY ieee;
	USE ieee.std_logic_1164.all;
	USE ieee.std_logic_signed.all;

--we create the entity upcount for our upcounter
	ENTITY upcount IS 

	  PORT ( Clear, Clock : IN STD_LOGIC; 
	         Q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)); 
	END upcount; 

	ARCHITECTURE Behavior OF upcount IS 
	 SIGNAL Count : STD_LOGIC_VECTOR(1 DOWNTO 0); 

	BEGIN 
	  PROCESS (Clock) 
	  BEGIN 

		 IF (Clock'EVENT AND Clock = '1') THEN 

		  IF Clear = '1' THEN 
			 Count <= "00"; 
		  ELSE 
			 Count <= Count + 1; 
		  END IF; 

		END IF; 
	  END PROCESS; 
	  Q <= Count; 

	END Behavior; 


	LIBRARY ieee;
	USE ieee.std_logic_1164.all;

--we create the entity dec3to8 for our 3 to 8 decoder 
	ENTITY dec3to8 IS


	  PORT ( W : IN STD_LOGIC_VECTOR(2 DOWNTO 0); 
	         En : IN STD_LOGIC; 
	         Y : OUT STD_LOGIC_VECTOR(0 TO 7)); 
	END dec3to8; 

	ARCHITECTURE Behavior OF dec3to8 IS 

	BEGIN 
	  PROCESS (W, En) 
	  BEGIN 

		 IF En = '1' THEN 

			CASE W IS 
			when "000" => Y<="10000000";
			when "001" => Y<="01000010";
			when "010" => Y<="00100000";
			when "011" => Y<="00010000";
			when "100" => Y<="00001000";
			when "101" => Y<="00000100";
			when "110" => Y<="00000010";
			when "111" => Y<="00000001";
			END CASE; 
		 ELSE 
			Y <= "00000000"; 
		 END IF; 
		END PROCESS; 
	END Behavior; 




	LIBRARY ieee;
	USE ieee.std_logic_1164.all;

--we create the entity regn for our 16-bits register
	ENTITY regn IS 
	  GENERIC (n : INTEGER := 16); 
	  PORT ( R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0); 

	         Rin, Clock : IN STD_LOGIC; 

	         Q : BUFFER STD_LOGIC_VECTOR(n-1 DOWNTO 0)); 
	END regn; 

	ARCHITECTURE Behavior OF regn IS 

	BEGIN 
	  PROCESS (Clock) 
	  BEGIN 

		 IF Clock'EVENT AND Clock = '1' THEN 
			IF Rin = '1' THEN 
			  Q <=R; 
			END IF; 
		 END IF; 
	  END PROCESS; 
	END Behavior; 