LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.cpu_package.all;

ENTITY cpu IS
	PORT(	
		Clock				: IN	STD_LOGIC;
		Fetch_led, ID_led, Execution_led, Mem_led, WriteBack_led	: OUT	STD_LOGIC;
		Hazard_led, Stall_led	: OUT	STD_LOGIC;
		data				: IN	STD_LOGIC_VECTOR(7 downto 0);
		opcode				: IN	STD_LOGIC_VECTOR(3 downto 0);
		codeRS, codeRT		: IN	STD_LOGIC_VECTOR(1 downto 0);
		hex0, hex1, hex2, hex3, hex4, hex5: OUT STD_LOGIC_VECTOR(6 downto 0);
		RS, RT				: BUFFER STD_LOGIC_VECTOR(7 downto 0);
		LEDR				: OUT STD_LOGIC_VECTOR(7 downto 0);
		LEDG				: OUT STD_LOGIC_VECTOR(2 downto 0);
		divisor_led			: OUT std_logic;
		
		SRAM_ADDR			: OUT	STD_LOGIC_VECTOR(19 DOWNTO 0);
		SRAM_DQ				: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		SRAM_CE_N			: OUT	STD_LOGIC;
		SRAM_OE_N			: OUT	STD_LOGIC;
		SRAM_WE_N			: OUT	STD_LOGIC;
		SRAM_UB_N			: OUT	STD_LOGIC;
		SRAM_LB_N			: OUT	STD_LOGIC
	);
END cpu;

ARCHITECTURE Behavior OF cpu IS
	SIGNAL R0, R1, R2, R3: STD_LOGIC_VECTOR(7 downto 0);
	
	COMPONENT Divider IS
		GENERIC (N_BITS : INTEGER := 8; M_BITS : INTEGER := 16);
		PORT ( clk : IN STD_LOGIC; clear : IN STD_LOGIC; Divisor_in : IN STD_LOGIC_VECTOR(N_BITS-1 DOWNTO 0); Dividend_in: IN STD_LOGIC_VECTOR(N_BITS-1 DOWNTO 0);
			   Done_Flag : OUT STD_LOGIC; Quotient_out : OUT STD_LOGIC_VECTOR(N_BITS-1 DOWNTO 0); Actual_Remainder_out : OUT STD_LOGIC_VECTOR(N_BITS-1 DOWNTO 0);
			   state_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0) );
	END COMPONENT;

	SIGNAL div_start, div_done, div_is_running, divisor_process : STD_LOGIC;
	SIGNAL div_dividend_in, div_divisor_in, div_quotient_out, div_remainder_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL div_state_out : STD_LOGIC_VECTOR(2 DOWNTO 0);
	
	TYPE State_type IS (Fetch, ID, Execution, Memory, WriteBack);
	SIGNAL s1, s2, s3, s4, s5 : State_type;
	SIGNAL stall_s : STD_LOGIC;
	
	SIGNAL opc1, opc2, opc3, opc4, opc5 : STD_LOGIC_VECTOR(3 downto 0);
	SIGNAL crs1, crs2, crs3, crs4, crs5 : STD_LOGIC_VECTOR(1 downto 0);
	SIGNAL crt1, crt2, crt3, crt4, crt5 : STD_LOGIC_VECTOR(1 downto 0);
	SIGNAL imm1, imm2, imm3, imm4, imm5 : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL rs_v1, rs_v2, rs_v3, rs_v4, rs_v5 : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL rt_v1, rt_v2, rt_v3, rt_v4, rt_v5 : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL alu1, alu2, alu3, alu4, alu5 : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL mem_data_out1, mem_data_out2, mem_data_out3, mem_data_out4, mem_data_out5 : STD_LOGIC_VECTOR(7 downto 0);

	-- NEW: Combinatorial signals to hold the immediate ALU results
	SIGNAL alu_result1, alu_result2, alu_result3, alu_result4, alu_result5 : STD_LOGIC_VECTOR(7 downto 0);
	
BEGIN

	Divider_Unit : Divider PORT MAP ( clk => Clock, clear => div_start, Divisor_in => div_divisor_in, Dividend_in => div_dividend_in, Done_Flag => div_done,
									   Quotient_out => div_quotient_out, Actual_Remainder_out => div_remainder_out, state_out => div_state_out );
	
	SRAM_Control_Process: PROCESS(s1, s2, s3, s4, s5, opc1, opc2, opc3, opc4, opc5, alu1, alu2, alu3, alu4, alu5, rs_v1, rs_v2, rs_v3, rs_v4, rs_v5)
		VARIABLE mem_stage_active : BOOLEAN;
	BEGIN
		SRAM_ADDR <= (OTHERS => '0'); SRAM_CE_N <= '1'; SRAM_OE_N <= '1'; SRAM_WE_N <= '1'; SRAM_DQ <= (OTHERS => 'Z');
		mem_stage_active := false;
		
		IF s1=Memory AND(opc1="1011" OR opc1="1010")THEN SRAM_ADDR<="000000000000"&alu1;SRAM_CE_N<='0';mem_stage_active:=true;IF opc1="1011" THEN SRAM_OE_N<='0';SRAM_WE_N<='1';ELSE SRAM_OE_N<='1';SRAM_WE_N<='0';SRAM_DQ<=rs_v1;END IF;
		ELSIF s2=Memory AND(opc2="1011" OR opc2="1010")THEN SRAM_ADDR<="000000000000"&alu2;SRAM_CE_N<='0';mem_stage_active:=true;IF opc2="1011" THEN SRAM_OE_N<='0';SRAM_WE_N<='1';ELSE SRAM_OE_N<='1';SRAM_WE_N<='0';SRAM_DQ<=rs_v2;END IF;
		ELSIF s3=Memory AND(opc3="1011" OR opc3="1010")THEN SRAM_ADDR<="000000000000"&alu3;SRAM_CE_N<='0';mem_stage_active:=true;IF opc3="1011" THEN SRAM_OE_N<='0';SRAM_WE_N<='1';ELSE SRAM_OE_N<='1';SRAM_WE_N<='0';SRAM_DQ<=rs_v3;END IF;
		ELSIF s4=Memory AND(opc4="1011" OR opc4="1010")THEN SRAM_ADDR<="000000000000"&alu4;SRAM_CE_N<='0';mem_stage_active:=true;IF opc4="1011" THEN SRAM_OE_N<='0';SRAM_WE_N<='1';ELSE SRAM_OE_N<='1';SRAM_WE_N<='0';SRAM_DQ<=rs_v4;END IF;
		ELSIF s5=Memory AND(opc5="1011" OR opc5="1010")THEN SRAM_ADDR<="000000000000"&alu5;SRAM_CE_N<='0';mem_stage_active:=true;IF opc5="1011" THEN SRAM_OE_N<='0';SRAM_WE_N<='1';ELSE SRAM_OE_N<='1';SRAM_WE_N<='0';SRAM_DQ<=rs_v5;END IF;
		END IF;
		
		IF NOT mem_stage_active THEN
			IF s1=WriteBack AND opc1="1011" THEN SRAM_ADDR<="000000000000"&alu1;SRAM_CE_N<='0';SRAM_OE_N<='0';ELSIF s2=WriteBack AND opc2="1011" THEN SRAM_ADDR<="000000000000"&alu2;SRAM_CE_N<='0';SRAM_OE_N<='0';
			ELSIF s3=WriteBack AND opc3="1011" THEN SRAM_ADDR<="000000000000"&alu3;SRAM_CE_N<='0';SRAM_OE_N<='0';ELSIF s4=WriteBack AND opc4="1011" THEN SRAM_ADDR<="000000000000"&alu4;SRAM_CE_N<='0';SRAM_OE_N<='0';
			ELSIF s5=WriteBack AND opc5="1011" THEN SRAM_ADDR<="000000000000"&alu5;SRAM_CE_N<='0';SRAM_OE_N<='0'; END IF;
		END IF;
		SRAM_UB_N <= '0'; SRAM_LB_N <= '0';
	END PROCESS SRAM_Control_Process;

	-- NEW: Combinatorial process for ALU logic. This calculates results immediately.
	ALU_Combinatorial_Logic: PROCESS(opc1, opc2, opc3, opc4, opc5, rs_v1, rt_v1, imm1, rs_v2, rt_v2, imm2, rs_v3, rt_v3, imm3, rs_v4, rt_v4, imm4, rs_v5, rt_v5, imm5)
	BEGIN
		-- ALU logic for Slot 1
		CASE opc1 IS WHEN"0000"=>alu_result1<=imm1;WHEN"0001"=>alu_result1<=rt_v1;WHEN"0010"=>alu_result1<=std_logic_vector(signed(rs_v1)+signed(rt_v1));WHEN"0101"=>alu_result1<=std_logic_vector(signed(rs_v1)-signed(rt_v1));WHEN"1001"=>alu_result1<=std_logic_vector(signed(rt_v1)-signed(rs_v1));WHEN"0011"=>alu_result1<=(rs_v1 AND rt_v1);WHEN"0110"=>alu_result1<=(rs_v1 NOR rt_v1);WHEN"0100"=>IF(signed(rs_v1)<signed(rt_v1))THEN alu_result1<="00000001";ELSE alu_result1<="00000000";END IF;WHEN"1000"=>alu_result1<=(OTHERS => 'X');WHEN"1011"|"1010"=>alu_result1<=rt_v1;WHEN OTHERS=>alu_result1<=(OTHERS => 'X');END CASE;
		-- ALU logic for Slot 2
		CASE opc2 IS WHEN"0000"=>alu_result2<=imm2;WHEN"0001"=>alu_result2<=rt_v2;WHEN"0010"=>alu_result2<=std_logic_vector(signed(rs_v2)+signed(rt_v2));WHEN"0101"=>alu_result2<=std_logic_vector(signed(rs_v2)-signed(rt_v2));WHEN"1001"=>alu_result2<=std_logic_vector(signed(rt_v2)-signed(rs_v2));WHEN"0011"=>alu_result2<=(rs_v2 AND rt_v2);WHEN"0110"=>alu_result2<=(rs_v2 NOR rt_v2);WHEN"0100"=>IF(signed(rs_v2)<signed(rt_v2))THEN alu_result2<="00000001";ELSE alu_result2<="00000000";END IF;WHEN"1000"=>alu_result2<=(OTHERS => 'X');WHEN"1011"|"1010"=>alu_result2<=rt_v2;WHEN OTHERS=>alu_result2<=(OTHERS => 'X');END CASE;
		-- ALU logic for Slot 3
		CASE opc3 IS WHEN"0000"=>alu_result3<=imm3;WHEN"0001"=>alu_result3<=rt_v3;WHEN"0010"=>alu_result3<=std_logic_vector(signed(rs_v3)+signed(rt_v3));WHEN"0101"=>alu_result3<=std_logic_vector(signed(rs_v3)-signed(rt_v3));WHEN"1001"=>alu_result3<=std_logic_vector(signed(rt_v3)-signed(rs_v3));WHEN"0011"=>alu_result3<=(rs_v3 AND rt_v3);WHEN"0110"=>alu_result3<=(rs_v3 NOR rt_v3);WHEN"0100"=>IF(signed(rs_v3)<signed(rt_v3))THEN alu_result3<="00000001";ELSE alu_result3<="00000000";END IF;WHEN"1000"=>alu_result3<=(OTHERS => 'X');WHEN"1011"|"1010"=>alu_result3<=rt_v3;WHEN OTHERS=>alu_result3<=(OTHERS => 'X');END CASE;
		-- ALU logic for Slot 4
		CASE opc4 IS WHEN"0000"=>alu_result4<=imm4;WHEN"0001"=>alu_result4<=rt_v4;WHEN"0010"=>alu_result4<=std_logic_vector(signed(rs_v4)+signed(rt_v4));WHEN"0101"=>alu_result4<=std_logic_vector(signed(rs_v4)-signed(rt_v4));WHEN"1001"=>alu_result4<=std_logic_vector(signed(rt_v4)-signed(rs_v4));WHEN"0011"=>alu_result4<=(rs_v4 AND rt_v4);WHEN"0110"=>alu_result4<=(rs_v4 NOR rt_v4);WHEN"0100"=>IF(signed(rs_v4)<signed(rt_v4))THEN alu_result4<="00000001";ELSE alu_result4<="00000000";END IF;WHEN"1000"=>alu_result4<=(OTHERS => 'X');WHEN"1011"|"1010"=>alu_result4<=rt_v4;WHEN OTHERS=>alu_result4<=(OTHERS => 'X');END CASE;
		-- ALU logic for Slot 5
		CASE opc5 IS WHEN"0000"=>alu_result5<=imm5;WHEN"0001"=>alu_result5<=rt_v5;WHEN"0010"=>alu_result5<=std_logic_vector(signed(rs_v5)+signed(rt_v5));WHEN"0101"=>alu_result5<=std_logic_vector(signed(rs_v5)-signed(rt_v5));WHEN"1001"=>alu_result5<=std_logic_vector(signed(rt_v5)-signed(rs_v5));WHEN"0011"=>alu_result5<=(rs_v5 AND rt_v5);WHEN"0110"=>alu_result5<=(rs_v5 NOR rt_v5);WHEN"0100"=>IF(signed(rs_v5)<signed(rt_v5))THEN alu_result5<="00000001";ELSE alu_result5<="00000000";END IF;WHEN"1000"=>alu_result5<=(OTHERS => 'X');WHEN"1011"|"1010"=>alu_result5<=rt_v5;WHEN OTHERS=>alu_result5<=(OTHERS => 'X');END CASE;
	END PROCESS ALU_Combinatorial_Logic;

	Pipeline_Process: PROCESS(Clock)
	BEGIN
		IF(rising_edge(Clock)) THEN
		    div_start<='0'; Hazard_led<='0'; stall_s<='0';
			
			IF(opcode="1110")THEN s1<=Fetch;s2<=WriteBack;s3<=Memory;s4<=Execution;s5<=ID;opc1<="1111";opc2<="1111";opc3<="1111";opc4<="1111";opc5<="1111";divisor_process<='0';div_is_running<='0';
			ELSIF(divisor_process='1')THEN divisor_led<='1';LEDG<=div_state_out;IF(div_is_running='0')THEN div_start<='1';div_is_running<='1';IF(s1=Execution)THEN div_dividend_in<=rs_v1;div_divisor_in<=rt_v1;ELSIF(s2=Execution)THEN div_dividend_in<=rs_v2;div_divisor_in<=rt_v2;ELSIF(s3=Execution)THEN div_dividend_in<=rs_v3;div_divisor_in<=rt_v3;ELSIF(s4=Execution)THEN div_dividend_in<=rs_v4;div_divisor_in<=rt_v4;ELSIF(s5=Execution)THEN div_dividend_in<=rs_v5;div_divisor_in<=rt_v5;END IF;ELSE IF(div_done='1')THEN divisor_process<='0';div_is_running<='0';IF(s1=Execution)THEN alu1<=div_quotient_out;ELSIF(s2=Execution)THEN alu2<=div_quotient_out;ELSIF(s3=Execution)THEN alu3<=div_quotient_out;ELSIF(s4=Execution)THEN alu4<=div_quotient_out;ELSIF(s5=Execution)THEN alu5<=div_quotient_out;END IF;END IF;END IF;
			ELSE
				divisor_led<='0';LEDG<="000";LEDR<=R0;Fetch_led<='0';ID_led<='0';Execution_led<='0';Mem_led<='0';WriteBack_led<='0';
				
				IF((opc5="1011")AND(opc1/="1111" AND(crs1=crs5 OR crt1=crs5)))OR((opc1="1011")AND(opc2/="1111" AND(crs2=crs1 OR crt2=crs1)))OR((opc2="1011")AND(opc3/="1111" AND(crs3=crs2 OR crt3=crs2)))OR((opc3="1011")AND(opc4/="1111" AND(crs4=crs3 OR crt4=crs3)))OR((opc4="1011")AND(opc5/="1111" AND(crs5=crs4 OR crt5=crs4)))THEN stall_s<='1';END IF;
				Stall_led<=stall_s;

				IF stall_s = '0' THEN
					-- Slot 1
					CASE s1 IS
						WHEN Fetch=> opc1<=opcode;crs1<=codeRS;crt1<=codeRT;imm1<=data;IF opcode/="1111" THEN Fetch_led<='1';END IF;s1<=ID;s2<=Fetch;
						WHEN ID=> CASE crs1 IS WHEN"00"=>rs_v1<=R0;WHEN"01"=>rs_v1<=R1;WHEN"10"=>rs_v1<=R2;WHEN"11"=>rs_v1<=R3;END CASE;CASE crt1 IS WHEN"00"=>rt_v1<=R0;WHEN"01"=>rt_v1<=R1;WHEN"10"=>rt_v1<=R2;WHEN"11"=>rt_v1<=R3;END CASE;IF opc1/="0000" AND opc1/="1111" THEN IF opc5/="1111" AND opc5/="1010" AND crs5=crs1 THEN Hazard_led<='1';rs_v1<=alu_result5; ELSIF opc4/="1111" AND opc4/="1010" AND crs4=crs1 THEN Hazard_led<='1';rs_v1<=mem_data_out4; END IF; IF opc5/="1111" AND opc5/="1010" AND crs5=crt1 THEN Hazard_led<='1';rt_v1<=alu_result5; ELSIF opc4/="1111" AND opc4/="1010" AND crs4=crt1 THEN Hazard_led<='1';rt_v1<=mem_data_out4; END IF; END IF; IF opc1/="1111" THEN ID_led<='1';END IF;IF opc1="1000" THEN divisor_process<='1';END IF;s1<=Execution;
						WHEN Execution=> alu1 <= alu_result1; IF opc1/="1111" THEN Execution_led<='1';END IF;s1<=Memory; -- MODIFIED
						WHEN Memory=> mem_data_out1<=alu1;IF opc1/="1111" THEN Mem_led<='1';END IF;s1<=WriteBack;
						WHEN WriteBack=> IF(opc1/="1111" AND opc1/="1010" AND opc1/="1011")THEN CASE crs1 IS WHEN"00"=>R0<=mem_data_out1;WHEN"01"=>R1<=mem_data_out1;WHEN"10"=>R2<=mem_data_out1;WHEN"11"=>R3<=mem_data_out1;END CASE;END IF;IF(opc1="1011")THEN CASE crs1 IS WHEN"00"=>R0<=SRAM_DQ;WHEN"01"=>R1<=SRAM_DQ;WHEN"10"=>R2<=SRAM_DQ;WHEN"11"=>R3<=SRAM_DQ;END CASE;END IF;IF opc1/="1111" THEN WriteBack_led<='1';END IF;
					END CASE;
					-- Slot 2
					CASE s2 IS
						WHEN Fetch=> opc2<=opcode;crs2<=codeRS;crt2<=codeRT;imm2<=data;IF opcode/="1111" THEN Fetch_led<='1';END IF;s2<=ID;s3<=Fetch;
						WHEN ID=> CASE crs2 IS WHEN"00"=>rs_v2<=R0;WHEN"01"=>rs_v2<=R1;WHEN"10"=>rs_v2<=R2;WHEN"11"=>rs_v2<=R3;END CASE;CASE crt2 IS WHEN"00"=>rt_v2<=R0;WHEN"01"=>rt_v2<=R1;WHEN"10"=>rt_v2<=R2;WHEN"11"=>rt_v2<=R3;END CASE;IF opc2/="0000" AND opc2/="1111" THEN IF opc1/="1111" AND opc1/="1010" AND crs1=crs2 THEN Hazard_led<='1';rs_v2<=alu_result1; ELSIF opc5/="1111" AND opc5/="1010" AND crs5=crs2 THEN Hazard_led<='1';rs_v2<=mem_data_out5; END IF; IF opc1/="1111" AND opc1/="1010" AND crs1=crt2 THEN Hazard_led<='1';rt_v2<=alu_result1; ELSIF opc5/="1111" AND opc5/="1010" AND crs5=crt2 THEN Hazard_led<='1';rt_v2<=mem_data_out5; END IF; END IF; IF opc2/="1111" THEN ID_led<='1';END IF;IF opc2="1000" THEN divisor_process<='1';END IF;s2<=Execution;
						WHEN Execution=> alu2 <= alu_result2; IF opc2/="1111" THEN Execution_led<='1';END IF;s2<=Memory; -- MODIFIED
						WHEN Memory=> mem_data_out2<=alu2;IF opc2/="1111" THEN Mem_led<='1';END IF;s2<=WriteBack;
						WHEN WriteBack=> IF(opc2/="1111" AND opc2/="1010" AND opc2/="1011")THEN CASE crs2 IS WHEN"00"=>R0<=mem_data_out2;WHEN"01"=>R1<=mem_data_out2;WHEN"10"=>R2<=mem_data_out2;WHEN"11"=>R3<=mem_data_out2;END CASE;END IF;IF(opc2="1011")THEN CASE crs2 IS WHEN"00"=>R0<=SRAM_DQ;WHEN"01"=>R1<=SRAM_DQ;WHEN"10"=>R2<=SRAM_DQ;WHEN"11"=>R3<=SRAM_DQ;END CASE;END IF;IF opc2/="1111" THEN WriteBack_led<='1';END IF;
					END CASE;
					-- Slot 3
					CASE s3 IS
						WHEN Fetch=> opc3<=opcode;crs3<=codeRS;crt3<=codeRT;imm3<=data;IF opcode/="1111" THEN Fetch_led<='1';END IF;s3<=ID;s4<=Fetch;
						WHEN ID=> CASE crs3 IS WHEN"00"=>rs_v3<=R0;WHEN"01"=>rs_v3<=R1;WHEN"10"=>rs_v3<=R2;WHEN"11"=>rs_v3<=R3;END CASE;CASE crt3 IS WHEN"00"=>rt_v3<=R0;WHEN"01"=>rt_v3<=R1;WHEN"10"=>rt_v3<=R2;WHEN"11"=>rt_v3<=R3;END CASE;IF opc3/="0000" AND opc3/="1111" THEN IF opc2/="1111" AND opc2/="1010" AND crs2=crs3 THEN Hazard_led<='1';rs_v3<=alu_result2; ELSIF opc1/="1111" AND opc1/="1010" AND crs1=crs3 THEN Hazard_led<='1';rs_v3<=mem_data_out1; END IF; IF opc2/="1111" AND opc2/="1010" AND crs2=crt3 THEN Hazard_led<='1';rt_v3<=alu_result2; ELSIF opc1/="1111" AND opc1/="1010" AND crs1=crt3 THEN Hazard_led<='1';rt_v3<=mem_data_out1; END IF; END IF; IF opc3/="1111" THEN ID_led<='1';END IF;IF opc3="1000" THEN divisor_process<='1';END IF;s3<=Execution;
						WHEN Execution=> alu3 <= alu_result3; IF opc3/="1111" THEN Execution_led<='1';END IF;s3<=Memory; -- MODIFIED
						WHEN Memory=> mem_data_out3<=alu3;IF opc3/="1111" THEN Mem_led<='1';END IF;s3<=WriteBack;
						WHEN WriteBack=> IF(opc3/="1111" AND opc3/="1010" AND opc3/="1011")THEN CASE crs3 IS WHEN"00"=>R0<=mem_data_out3;WHEN"01"=>R1<=mem_data_out3;WHEN"10"=>R2<=mem_data_out3;WHEN"11"=>R3<=mem_data_out3;END CASE;END IF;IF(opc3="1011")THEN CASE crs3 IS WHEN"00"=>R0<=SRAM_DQ;WHEN"01"=>R1<=SRAM_DQ;WHEN"10"=>R2<=SRAM_DQ;WHEN"11"=>R3<=SRAM_DQ;END CASE;END IF;IF opc3/="1111" THEN WriteBack_led<='1';END IF;
					END CASE;
					-- Slot 4
					CASE s4 IS
						WHEN Fetch=> opc4<=opcode;crs4<=codeRS;crt4<=codeRT;imm4<=data;IF opcode/="1111" THEN Fetch_led<='1';END IF;s4<=ID;s5<=Fetch;
						WHEN ID=> CASE crs4 IS WHEN"00"=>rs_v4<=R0;WHEN"01"=>rs_v4<=R1;WHEN"10"=>rs_v4<=R2;WHEN"11"=>rs_v4<=R3;END CASE;CASE crt4 IS WHEN"00"=>rt_v4<=R0;WHEN"01"=>rt_v4<=R1;WHEN"10"=>rt_v4<=R2;WHEN"11"=>rt_v4<=R3;END CASE;IF opc4/="0000" AND opc4/="1111" THEN IF opc3/="1111" AND opc3/="1010" AND crs3=crs4 THEN Hazard_led<='1';rs_v4<=alu_result3; ELSIF opc2/="1111" AND opc2/="1010" AND crs2=crs4 THEN Hazard_led<='1';rs_v4<=mem_data_out2; END IF; IF opc3/="1111" AND opc3/="1010" AND crs3=crt4 THEN Hazard_led<='1';rt_v4<=alu_result3; ELSIF opc2/="1111" AND opc2/="1010" AND crs2=crt4 THEN Hazard_led<='1';rt_v4<=mem_data_out2; END IF; END IF; IF opc4/="1111" THEN ID_led<='1';END IF;IF opc4="1000" THEN divisor_process<='1';END IF;s4<=Execution;
						WHEN Execution=> alu4 <= alu_result4; IF opc4/="1111" THEN Execution_led<='1';END IF;s4<=Memory; -- MODIFIED
						WHEN Memory=> mem_data_out4<=alu4;IF opc4/="1111" THEN Mem_led<='1';END IF;s4<=WriteBack;
						WHEN WriteBack=> IF(opc4/="1111" AND opc4/="1010" AND opc4/="1011")THEN CASE crs4 IS WHEN"00"=>R0<=mem_data_out4;WHEN"01"=>R1<=mem_data_out4;WHEN"10"=>R2<=mem_data_out4;WHEN"11"=>R3<=mem_data_out4;END CASE;END IF;IF(opc4="1011")THEN CASE crs4 IS WHEN"00"=>R0<=SRAM_DQ;WHEN"01"=>R1<=SRAM_DQ;WHEN"10"=>R2<=SRAM_DQ;WHEN"11"=>R3<=SRAM_DQ;END CASE;END IF;IF opc4/="1111" THEN WriteBack_led<='1';END IF;
					END CASE;
					-- Slot 5
					CASE s5 IS
						WHEN Fetch=> opc5<=opcode;crs5<=codeRS;crt5<=codeRT;imm5<=data;IF opcode/="1111" THEN Fetch_led<='1';END IF;s5<=ID;s1<=Fetch;
						WHEN ID=> CASE crs5 IS WHEN"00"=>rs_v5<=R0;WHEN"01"=>rs_v5<=R1;WHEN"10"=>rs_v5<=R2;WHEN"11"=>rs_v5<=R3;END CASE;CASE crt5 IS WHEN"00"=>rt_v5<=R0;WHEN"01"=>rt_v5<=R1;WHEN"10"=>rt_v5<=R2;WHEN"11"=>rt_v5<=R3;END CASE;IF opc5/="0000" AND opc5/="1111" THEN IF opc4/="1111" AND opc4/="1010" AND crs4=crs5 THEN Hazard_led<='1';rs_v5<=alu_result4; ELSIF opc3/="1111" AND opc3/="1010" AND crs3=crs5 THEN Hazard_led<='1';rs_v5<=mem_data_out3; END IF; IF opc4/="1111" AND opc4/="1010" AND crs4=crt5 THEN Hazard_led<='1';rt_v5<=alu_result4; ELSIF opc3/="1111" AND opc3/="1010" AND crs3=crt5 THEN Hazard_led<='1';rt_v5<=mem_data_out3; END IF; END IF; IF opc5/="1111" THEN ID_led<='1';END IF;IF opc5="1000" THEN divisor_process<='1';END IF;s5<=Execution;
						WHEN Execution=> alu5 <= alu_result5; IF opc5/="1111" THEN Execution_led<='1';END IF;s5<=Memory; -- MODIFIED
						WHEN Memory=> mem_data_out5<=alu5;IF opc5/="1111" THEN Mem_led<='1';END IF;s5<=WriteBack;
						WHEN WriteBack=> IF(opc5/="1111" AND opc5/="1010" AND opc5/="1011")THEN CASE crs5 IS WHEN"00"=>R0<=mem_data_out5;WHEN"01"=>R1<=mem_data_out5;WHEN"10"=>R2<=mem_data_out5;WHEN"11"=>R3<=mem_data_out5;END CASE;END IF;IF(opc5="1011")THEN CASE crs5 IS WHEN"00"=>R0<=SRAM_DQ;WHEN"01"=>R1<=SRAM_DQ;WHEN"10"=>R2<=SRAM_DQ;WHEN"11"=>R3<=SRAM_DQ;END CASE;END IF;IF opc5/="1111" THEN WriteBack_led<='1';END IF;
					END CASE;
				END IF;
			END IF;
		END IF;
	END PROCESS Pipeline_Process;
	
	Display_Process: PROCESS(codeRS, codeRT, R0, R1, R2, R3)
	BEGIN
		CASE codeRS IS WHEN"00"=>RS<=R0;WHEN"01"=>RS<=R1;WHEN"10"=>RS<=R2;WHEN"11"=>RS<=R3;WHEN OTHERS=>RS<=(OTHERS=>'X');END CASE;
		CASE codeRT IS WHEN"00"=>RT<=R0;WHEN"01"=>RT<=R1;WHEN"10"=>RT<=R2;WHEN"11"=>RT<=R3;WHEN OTHERS=>RT<=(OTHERS=>'X');END CASE;
	END PROCESS Display_Process;
	
	stage0:hex port map(data(3 downto 0),hex0);stage1:hex port map(data(7 downto 4),hex1);
	stage2:hex port map(RS(3 downto 0),hex2);stage3:hex port map(RS(7 downto 4),hex3);
	stage4:hex port map(RT(3 downto 0),hex4);stage5:hex port map(RT(7 downto 4),hex5);
	
END Behavior;