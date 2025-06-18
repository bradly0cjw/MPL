LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.cpu_package.all;    -- Assuming this package contains the 'hex' component definition.

ENTITY cpu IS
	PORT(	Clock	:IN	STD_LOGIC;
			Fetch_led, ID_led, Execution_led, WriteBack_led, Hazard	:OUT	STD_LOGIC;
			data				:IN	STD_LOGIC_VECTOR(7 downto 0);
			opcode			:IN	STD_LOGIC_VECTOR(3 downto 0);
			codeRS, codeRT	:IN	STD_LOGIC_VECTOR(1 downto 0);
			hex0, hex1, hex2, hex3, hex4, hex5:OUT STD_LOGIC_VECTOR(6 downto 0);
			RS, RT:BUFFER STD_LOGIC_VECTOR(7 downto 0);
			LEDR : OUT STD_LOGIC_VECTOR(7 downto 0);
            LEDG : OUT STD_LOGIC_VECTOR(2 downto 0);
			divisor_led : OUT std_logic
			);
END cpu;

ARCHITECTURE Behavior OF cpu IS
	-- General purpose registers
	SIGNAL R0, R1, R2, R3: STD_LOGIC_VECTOR(7 downto 0);
	
	-- Component declaration for the external Divider module
	COMPONENT Divider IS
		GENERIC (
			N_BITS : INTEGER := 8;
			M_BITS : INTEGER := 16
		);
		PORT (
			clk        : IN  STD_LOGIC;
			clear      : IN  STD_LOGIC;
			Divisor_in : IN  STD_LOGIC_VECTOR(N_BITS-1 DOWNTO 0);
			Dividend_in: IN  STD_LOGIC_VECTOR(N_BITS-1 DOWNTO 0);
			Done_Flag  : OUT STD_LOGIC;
			Quotient_out : OUT STD_LOGIC_VECTOR(N_BITS-1 DOWNTO 0);
			Actual_Remainder_out : OUT STD_LOGIC_VECTOR(N_BITS-1 DOWNTO 0);
			state_out  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
		);
	END COMPONENT;

	-- Signals for interfacing with the Divider component
	SIGNAL div_start         : STD_LOGIC;
	SIGNAL div_done          : STD_LOGIC;
	SIGNAL div_is_running    : STD_LOGIC;
	SIGNAL div_dividend_in   : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL div_divisor_in    : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL div_quotient_out  : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL div_remainder_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL div_state_out     : STD_LOGIC_VECTOR(2 DOWNTO 0);
	
	-- Pipeline stage control and data signals
	TYPE State_type2 IS(Fetch,ID,Execution,WriteBack);
	SIGNAL register1,register2,register3,register4 : State_type2;
	SIGNAL RS1, RT1, RS2, RT2, RS3, RT3, RS4, RT4: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL data1, data2, data3, data4 : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL codeRS1, codeRT1, codeRS2, codeRT2, codeRS3, codeRT3, codeRS4, codeRT4: STD_LOGIC_VECTOR(1 downto 0);
	SIGNAL opcode1, opcode2, opcode3, opcode4: STD_LOGIC_VECTOR(3 downto 0);
	SIGNAL divisor_process: std_logic;
	
BEGIN

	-- Instantiate the external Divider component
	Divider_Unit : Divider
		GENERIC MAP (
			N_BITS => 8,
			M_BITS => 16
		)
		PORT MAP (
			clk                  => Clock,
			clear                => div_start,
			Divisor_in           => div_divisor_in,
			Dividend_in          => div_dividend_in,
			Done_Flag            => div_done,
			Quotient_out         => div_quotient_out,
			Actual_Remainder_out => div_remainder_out,
			state_out            => div_state_out
		);


	PROCESS(Clock)
	BEGIN
		IF(rising_edge(Clock))THEN
		    -- Default assignments for divider control signals to avoid latches
		    div_start <= '0';
			Hazard <= '0'; -- Default hazard to off

			IF(opcode="1110") THEN -- Custom Reset
				register1 <= Fetch;
				register2 <= WriteBack;
				register3 <= Execution;
				register4 <= ID;
				opcode1 <= "1111";
				opcode2 <= "1111";
				opcode3 <= "1111";
				opcode4 <= "1111";
				divisor_process <= '0';
				div_is_running <= '0'; 
				
			ELSE
				-- If a division is in progress, stall the entire pipeline.
				IF(divisor_process = '1')THEN
					LEDR <= div_quotient_out;
					LEDG <= div_state_out; 
					
					IF (div_is_running = '0') THEN
					    -- First cycle of the stall. Start the division.
					    div_start <= '1';
					    div_is_running <= '1';
					    divisor_led <= '1';
					    
					    -- Latch the divider's inputs based on which pipeline slot is in Execution
                        IF(register1 = Execution)THEN div_dividend_in <= RS1; div_divisor_in <= RT1;
                        ELSIF(register2 = Execution)THEN div_dividend_in <= RS2; div_divisor_in <= RT2;
                        ELSIF(register3 = Execution)THEN div_dividend_in <= RS3; div_divisor_in <= RT3;
                        ELSIF(register4 = Execution)THEN div_dividend_in <= RS4; div_divisor_in <= RT4;
                        END IF;
					ELSE
					    -- Division is running. Wait for it to finish.
					    IF (div_done = '1') THEN
					        -- Division finished. Un-stall the pipeline for the next cycle.
					        divisor_process <= '0'; 
					        div_is_running <= '0';
					        divisor_led <= '0';
					        
					        -- Write the result into the destination register of the DIV instruction.
                            IF(register1 = Execution)THEN RS1 <= div_quotient_out;
                            ELSIF(register2 = Execution)THEN RS2 <= div_quotient_out;
                            ELSIF(register3 = Execution)THEN RS3 <= div_quotient_out;
                            ELSIF(register4 = Execution)THEN RS4 <= div_quotient_out;
                            END IF;
					    END IF;
					END IF;

				ELSE -- Normal Pipeline Operation (not stalled)
					div_is_running <= '0';
					LEDR <= R0; 
					LEDG <= "000";
					divisor_led <= '0';
				
					-- The following four CASE statements implement the rotating 4-stage pipeline.
					
					-- Logic for pipeline slot 1
					CASE register1 IS
						WHEN Fetch=>
							opcode1<=opcode; codeRS1<=codeRS; codeRT1<=codeRT; data1<=data;
							register1<=ID; register2<=Fetch;
							IF(opcode = "1111")THEN Fetch_led <= '0'; ELSE Fetch_led <= '1'; END IF;
						WHEN ID=>
							--- FIXED: Enhanced Hazard Unit with WB -> ID and EX -> ID forwarding.
							-- Priority 1: Forward from Execution stage (slot 4)
							IF(opcode4 /= "1111" AND opcode1 /= "1111" AND (codeRS1 = codeRS4 OR codeRT1 = codeRS4))THEN
								Hazard <= '1';
								IF(codeRS1 = codeRS4 AND codeRT1 = codeRS4)THEN RS1 <= RS4; RT1 <= RS4;
								ELSIF(codeRS1 = codeRS4)THEN RS1 <= RS4; CASE codeRT1 IS WHEN "00"=>RT1<=R0; WHEN "01"=>RT1<=R1; WHEN "10"=>RT1<=R2; WHEN "11"=>RT1<=R3; END CASE;
								ELSE RT1 <= RS4; CASE codeRS1 IS WHEN "00"=>RS1<=R0; WHEN "01"=>RS1<=R1; WHEN "10"=>RS1<=R2; WHEN "11"=>RS1<=R3; END CASE;
								END IF;
							-- Priority 2: Forward from WriteBack stage (slot 3)
							ELSIF(opcode3 /= "1111" AND opcode1 /= "1111" AND (codeRS1 = codeRS3 OR codeRT1 = codeRS3))THEN
								Hazard <= '1';
								IF(codeRS1 = codeRS3 AND codeRT1 = codeRS3)THEN RS1 <= RS3; RT1 <= RS3;
								ELSIF(codeRS1 = codeRS3)THEN RS1 <= RS3; CASE codeRT1 IS WHEN "00"=>RT1<=R0; WHEN "01"=>RT1<=R1; WHEN "10"=>RT1<=R2; WHEN "11"=>RT1<=R3; END CASE;
								ELSE RT1 <= RS3; CASE codeRS1 IS WHEN "00"=>RS1<=R0; WHEN "01"=>RS1<=R1; WHEN "10"=>RS1<=R2; WHEN "11"=>RS1<=R3; END CASE;
								END IF;
							ELSE -- No hazard, read from register file
								CASE codeRS1 IS WHEN "00"=>RS1<=R0; WHEN "01"=>RS1<=R1; WHEN "10"=>RS1<=R2; WHEN "11"=>RS1<=R3; END CASE;
								CASE codeRT1 IS WHEN "00"=>RT1<=R0; WHEN "01"=>RT1<=R1; WHEN "10"=>RT1<=R2; WHEN "11"=>RT1<=R3; END CASE;
							END IF;
							
							IF(opcode1 = "1000")THEN divisor_process <= '1'; END IF;
							IF(opcode1 = "1111")THEN ID_led <= '0'; ELSE ID_led <= '1'; END IF;
							register1<=Execution;
						WHEN Execution=>
							CASE opcode1 IS
								WHEN "0000" => RS1 <= data1;
								WHEN "0001" => RS1 <= RT1;
								WHEN "0010" => RS1 <= std_logic_vector(signed(RS1) + signed(RT1));
								WHEN "0101" => RS1 <= std_logic_vector(signed(RS1) - signed(RT1));
								WHEN "1001" => RS1 <= std_logic_vector(signed(RT1) - signed(RS1));
								WHEN "0011" => RS1 <= (RS1 AND RT1);
								WHEN "0110" => RS1 <= (RS1 NOR RT1);
								WHEN "0100" => IF(signed(RS1)<signed(RT1))THEN RS1 <= "00000001"; ELSE RS1 <= "00000000"; END IF;
								WHEN "1000" => null; -- Result is written by the stall control logic
								WHEN OTHERS => null;
							END CASE;
							IF(opcode1 = "1111")THEN Execution_led <= '0'; ELSE Execution_led <= '1'; END IF;
							register1<=WriteBack;
						WHEN WriteBack=>
							IF(opcode1 /= "1111")THEN CASE codeRS1 IS WHEN "00"=>R0<=RS1; WHEN "01"=>R1<=RS1; WHEN "10"=>R2<=RS1; WHEN "11"=>R3<=RS1; END CASE; END IF;
							IF(opcode1 = "1111")THEN WriteBack_led <= '0'; ELSE WriteBack_led <= '1'; END IF;
					END CASE;
					
					-- Logic for pipeline slot 2
					CASE register2 IS
						WHEN Fetch=>
							opcode2<=opcode; codeRS2<=codeRS; codeRT2<=codeRT; data2<=data;
							register2<=ID; register3<=Fetch;
							IF(opcode = "1111")THEN Fetch_led <= '0'; ELSE Fetch_led <= '1'; END IF;
						WHEN ID=>
							--- FIXED: Enhanced Hazard Unit with WB -> ID and EX -> ID forwarding.
							-- Priority 1: Forward from Execution stage (slot 1)
							IF(opcode1 /= "1111" AND opcode2 /= "1111" AND (codeRS2 = codeRS1 OR codeRT2 = codeRS1))THEN
								Hazard <= '1';
								IF(codeRS2 = codeRS1 AND codeRT2 = codeRS1)THEN RS2 <= RS1; RT2 <= RS1;
								ELSIF(codeRS2 = codeRS1)THEN RS2 <= RS1; CASE codeRT2 IS WHEN "00"=>RT2<=R0; WHEN "01"=>RT2<=R1; WHEN "10"=>RT2<=R2; WHEN "11"=>RT2<=R3; END CASE;
								ELSE RT2 <= RS1; CASE codeRS2 IS WHEN "00"=>RS2<=R0; WHEN "01"=>RS2<=R1; WHEN "10"=>RS2<=R2; WHEN "11"=>RS2<=R3; END CASE;
								END IF;
							-- Priority 2: Forward from WriteBack stage (slot 4)
							ELSIF(opcode4 /= "1111" AND opcode2 /= "1111" AND (codeRS2 = codeRS4 OR codeRT2 = codeRS4))THEN
								Hazard <= '1';
								IF(codeRS2 = codeRS4 AND codeRT2 = codeRS4)THEN RS2 <= RS4; RT2 <= RS4;
								ELSIF(codeRS2 = codeRS4)THEN RS2 <= RS4; CASE codeRT2 IS WHEN "00"=>RT2<=R0; WHEN "01"=>RT2<=R1; WHEN "10"=>RT2<=R2; WHEN "11"=>RT2<=R3; END CASE;
								ELSE RT2 <= RS4; CASE codeRS2 IS WHEN "00"=>RS2<=R0; WHEN "01"=>RS2<=R1; WHEN "10"=>RS2<=R2; WHEN "11"=>RS2<=R3; END CASE;
								END IF;
							ELSE -- No hazard, read from register file
								CASE codeRS2 IS WHEN "00"=>RS2<=R0; WHEN "01"=>RS2<=R1; WHEN "10"=>RS2<=R2; WHEN "11"=>RS2<=R3; END CASE;
								CASE codeRT2 IS WHEN "00"=>RT2<=R0; WHEN "01"=>RT2<=R1; WHEN "10"=>RT2<=R2; WHEN "11"=>RT2<=R3; END CASE;
							END IF;

							IF(opcode2="1000")THEN divisor_process<='1'; END IF;
							IF(opcode2="1111")THEN ID_led<='0'; ELSE ID_led<='1'; END IF;
							register2<=Execution;
						WHEN Execution=>
							CASE opcode2 IS
								WHEN "0000" => RS2 <= data2;
								WHEN "0001" => RS2 <= RT2;
								WHEN "0010" => RS2 <= std_logic_vector(signed(RS2) + signed(RT2));
								WHEN "0101" => RS2 <= std_logic_vector(signed(RS2) - signed(RT2));
								WHEN "1001" => RS2 <= std_logic_vector(signed(RT2) - signed(RS2));
								WHEN "0011" => RS2 <= (RS2 AND RT2);
								WHEN "0110" => RS2 <= (RS2 NOR RT2);
								WHEN "0100" => IF(signed(RS2)<signed(RT2))THEN RS2<="00000001"; ELSE RS2<="00000000"; END IF;
								WHEN "1000" => null;
								WHEN OTHERS => null;
							END CASE;
							IF(opcode2="1111")THEN Execution_led<='0'; ELSE Execution_led<='1'; END IF;
							register2<=WriteBack;
						WHEN WriteBack=>
							IF(opcode2/="1111")THEN CASE codeRS2 IS WHEN "00"=>R0<=RS2; WHEN "01"=>R1<=RS2; WHEN "10"=>R2<=RS2; WHEN "11"=>R3<=RS2; END CASE; END IF;
							IF(opcode2="1111")THEN WriteBack_led<='0'; ELSE WriteBack_led<='1'; END IF;
					END CASE;
					
					-- Logic for pipeline slot 3
					CASE register3 IS
						WHEN Fetch=>
							opcode3<=opcode; codeRS3<=codeRS; codeRT3<=codeRT; data3<=data;
							register3<=ID; register4<=Fetch;
							IF(opcode = "1111")THEN Fetch_led <= '0'; ELSE Fetch_led <= '1'; END IF;
						WHEN ID=>
							--- FIXED: Enhanced Hazard Unit with WB -> ID and EX -> ID forwarding.
							-- Priority 1: Forward from Execution stage (slot 2)
							IF(opcode2 /= "1111" AND opcode3 /= "1111" AND (codeRS3 = codeRS2 OR codeRT3 = codeRS2))THEN
								Hazard <= '1';
								IF(codeRS3 = codeRS2 AND codeRT3 = codeRS2)THEN RS3 <= RS2; RT3 <= RS2;
								ELSIF(codeRS3 = codeRS2)THEN RS3 <= RS2; CASE codeRT3 IS WHEN "00"=>RT3<=R0; WHEN "01"=>RT3<=R1; WHEN "10"=>RT3<=R2; WHEN "11"=>RT3<=R3; END CASE;
								ELSE RT3 <= RS2; CASE codeRS3 IS WHEN "00"=>RS3<=R0; WHEN "01"=>RS3<=R1; WHEN "10"=>RS3<=R2; WHEN "11"=>RS3<=R3; END CASE;
								END IF;
							-- Priority 2: Forward from WriteBack stage (slot 1)
							ELSIF(opcode1 /= "1111" AND opcode3 /= "1111" AND (codeRS3 = codeRS1 OR codeRT3 = codeRS1))THEN
								Hazard <= '1';
								IF(codeRS3 = codeRS1 AND codeRT3 = codeRS1)THEN RS3 <= RS1; RT3 <= RS1;
								ELSIF(codeRS3 = codeRS1)THEN RS3 <= RS1; CASE codeRT3 IS WHEN "00"=>RT3<=R0; WHEN "01"=>RT3<=R1; WHEN "10"=>RT3<=R2; WHEN "11"=>RT3<=R3; END CASE;
								ELSE RT3 <= RS1; CASE codeRS3 IS WHEN "00"=>RS3<=R0; WHEN "01"=>RS3<=R1; WHEN "10"=>RS3<=R2; WHEN "11"=>RS3<=R3; END CASE;
								END IF;
							ELSE -- No hazard, read from register file
								CASE codeRS3 IS WHEN "00"=>RS3<=R0; WHEN "01"=>RS3<=R1; WHEN "10"=>RS3<=R2; WHEN "11"=>RS3<=R3; END CASE;
								CASE codeRT3 IS WHEN "00"=>RT3<=R0; WHEN "01"=>RT3<=R1; WHEN "10"=>RT3<=R2; WHEN "11"=>RT3<=R3; END CASE;
							END IF;
							
							IF(opcode3="1000")THEN divisor_process<='1'; END IF;
							IF(opcode3="1111")THEN ID_led<='0'; ELSE ID_led<='1'; END IF;
							register3<=Execution;
						WHEN Execution=>
							CASE opcode3 IS
								WHEN "0000" => RS3 <= data3;
								WHEN "0001" => RS3 <= RT3;
								WHEN "0010" => RS3 <= std_logic_vector(signed(RS3) + signed(RT3));
								WHEN "0101" => RS3 <= std_logic_vector(signed(RS3) - signed(RT3));
								WHEN "1001" => RS3 <= std_logic_vector(signed(RT3) - signed(RS3));
								WHEN "0011" => RS3 <= (RS3 AND RT3);
								WHEN "0110" => RS3 <= (RS3 NOR RT3);
								WHEN "0100" => IF(signed(RS3)<signed(RT3))THEN RS3<="00000001"; ELSE RS3<="00000000"; END IF;
								WHEN "1000" => null;
								WHEN OTHERS => null;
							END CASE;
							IF(opcode3="1111")THEN Execution_led<='0'; ELSE Execution_led<='1'; END IF;
							register3<=WriteBack;
						WHEN WriteBack=>
							IF(opcode3/="1111")THEN CASE codeRS3 IS WHEN "00"=>R0<=RS3; WHEN "01"=>R1<=RS3; WHEN "10"=>R2<=RS3; WHEN "11"=>R3<=RS3; END CASE; END IF;
							IF(opcode3="1111")THEN WriteBack_led<='0'; ELSE WriteBack_led<='1'; END IF;
					END CASE;
					
					-- Logic for pipeline slot 4
					CASE register4 IS
						WHEN Fetch=>
							opcode4<=opcode; codeRS4<=codeRS; codeRT4<=codeRT; data4<=data;
							register4<=ID; register1<=Fetch;
							IF(opcode = "1111")THEN Fetch_led <= '0'; ELSE Fetch_led <= '1'; END IF;
						WHEN ID=>
							--- FIXED: Enhanced Hazard Unit with WB -> ID and EX -> ID forwarding.
							-- Priority 1: Forward from Execution stage (slot 3)
							IF(opcode3 /= "1111"  AND opcode4 /= "1111" AND (codeRS4 = codeRS3 OR codeRT4 = codeRS3))THEN
								Hazard <= '1';
								IF(codeRS4 = codeRS3 AND codeRT4 = codeRS3)THEN RS4 <= RS3; RT4 <= RS3;
								ELSIF(codeRS4 = codeRS3)THEN RS4 <= RS3; CASE codeRT4 IS WHEN "00"=>RT4<=R0; WHEN "01"=>RT4<=R1; WHEN "10"=>RT4<=R2; WHEN "11"=>RT4<=R3; END CASE;
								ELSE RT4 <= RS3; CASE codeRS4 IS WHEN "00"=>RS4<=R0; WHEN "01"=>RS4<=R1; WHEN "10"=>RS4<=R2; WHEN "11"=>RS4<=R3; END CASE;
								END IF;
							-- Priority 2: Forward from WriteBack stage (slot 2)
							ELSIF(opcode2 /= "1111" AND opcode4 /= "1111" AND (codeRS4 = codeRS2 OR codeRT4 = codeRS2))THEN
								Hazard <= '1';
								IF(codeRS4 = codeRS2 AND codeRT4 = codeRS2)THEN RS4 <= RS2; RT4 <= RS2;
								ELSIF(codeRS4 = codeRS2)THEN RS4 <= RS2; CASE codeRT4 IS WHEN "00"=>RT4<=R0; WHEN "01"=>RT4<=R1; WHEN "10"=>RT4<=R2; WHEN "11"=>RT4<=R3; END CASE;
								ELSE RT4 <= RS2; CASE codeRS4 IS WHEN "00"=>RS4<=R0; WHEN "01"=>RS4<=R1; WHEN "10"=>RS4<=R2; WHEN "11"=>RS4<=R3; END CASE;
								END IF;
							ELSE -- No hazard, read from register file
								CASE codeRS4 IS WHEN "00"=>RS4<=R0; WHEN "01"=>RS4<=R1; WHEN "10"=>RS4<=R2; WHEN "11"=>RS4<=R3; END CASE;
								CASE codeRT4 IS WHEN "00"=>RT4<=R0; WHEN "01"=>RT4<=R1; WHEN "10"=>RT4<=R2; WHEN "11"=>RT4<=R3; END CASE;
							END IF;
							
							IF(opcode4="1000")THEN divisor_process<='1'; END IF;
							IF(opcode4="1111")THEN ID_led<='0'; ELSE ID_led<='1'; END IF;
							register4<=Execution;
						WHEN Execution=>
							CASE opcode4 IS
								WHEN "0000" => RS4 <= data4;
								WHEN "0001" => RS4 <= RT4;
								WHEN "0010" => RS4 <= std_logic_vector(signed(RS4) + signed(RT4));
								WHEN "0101" => RS4 <= std_logic_vector(signed(RS4) - signed(RT4));
								WHEN "1001" => RS4 <= std_logic_vector(signed(RT4) - signed(RS4));
								WHEN "0011" => RS4 <= (RS4 AND RT4);
								WHEN "0110" => RS4 <= (RS4 NOR RT4);
								WHEN "0100" => IF(signed(RS4)<signed(RT4))THEN RS4<="00000001"; ELSE RS4<="00000000"; END IF;
								WHEN "1000" => null;
								WHEN OTHERS => null;
							END CASE;
							IF(opcode4="1111")THEN Execution_led<='0'; ELSE Execution_led<='1'; END IF;
							register4<=WriteBack;
						WHEN WriteBack=>
							IF(opcode4/="1111")THEN CASE codeRS4 IS WHEN "00"=>R0<=RS4; WHEN "01"=>R1<=RS4; WHEN "10"=>R2<=RS4; WHEN "11"=>R3<=RS4; END CASE; END IF;
							IF(opcode4="1111")THEN WriteBack_led<='0'; ELSE WriteBack_led<='1'; END IF;
					END CASE;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
	-- This process multiplexes the register file outputs to the top-level RS and RT ports.
	PROCESS(codeRS, codeRT, R0, R1, R2, R3)
	BEGIN
		CASE codeRS IS
			WHEN "00" => RS <= R0; WHEN "01" => RS <= R1;
			WHEN "10" => RS <= R2; WHEN "11" => RS <= R3;
			WHEN OTHERS => RS <= (OTHERS => 'X');
		END CASE;

		CASE codeRT IS
			WHEN "00" => RT <= R0; WHEN "01" => RT <= R1;
			WHEN "10" => RT <= R2; WHEN "11" => RT <= R3;
			WHEN OTHERS => RT <= (OTHERS => 'X');
		END CASE;
	END PROCESS;
	
	-- Display drivers for 7-segment displays
	stage0: hex port map(data(3 downto 0),hex0);
	stage1: hex port map(data(7 downto 4),hex1);
	stage2: hex port map(RS(3 downto 0),hex2);
	stage3: hex port map(RS(7 downto 4),hex3);
	stage4: hex port map(RT(3 downto 0),hex4);
	stage5: hex port map(RT(7 downto 4),hex5);
	
END Behavior;