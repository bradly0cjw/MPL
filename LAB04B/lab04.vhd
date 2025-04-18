LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.SevenSegment_Pkg.all;
USE work.AluBit_Pkg.all;

ENTITY lab04 IS
    PORT (
        A       : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        B       : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        Opcode  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        HEX0    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END ENTITY lab04;

ARCHITECTURE Structural OF lab04 IS

    -- Array Type Definition (moved from signal declaration)
    TYPE type_AluOutputArray IS ARRAY(0 TO 6) OF type_OneBitAluResult;

    -- Internal Signals
    SIGNAL INTERNAL_CARRY : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL INTERNAL_SET   : STD_LOGIC_VECTOR(6 DOWNTO 0); -- Still useful maybe, or remove if not needed
    SIGNAL Result_Internal: STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL alu_bit_outputs: type_AluOutputArray;
    SIGNAL hex0_input     : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL hex1_input     : STD_LOGIC_VECTOR(3 DOWNTO 0);
	 
	 signal Result  :  STD_LOGIC_VECTOR(6 DOWNTO 0);

    -- Signals specifically for corrected SLT
    SIGNAL sign_bit_msb   : STD_LOGIC; -- Raw sign bit from A-B subtraction at MSB
    SIGNAL overflow_slt   : STD_LOGIC; -- Overflow condition for SLT/SUB operation
    SIGNAL final_slt_value: STD_LOGIC; -- The '1' or '0' result for SLT

BEGIN

    -- Define the initial carry-in
	 with opcode select
		INTERNAL_CARRY(0) <= '1' when "0110",
									'1' when "0111",
									'0' when others;
									
    --INTERNAL_CARRY(0) <= '0';

    -- Generate the 7 ALU calculation calls
    ALU_CALC_GEN: FOR i IN 0 TO 6 GENERATE
        -- The function call itself doesn't need conditional 'less' input anymore
        -- We compute the final SLT value *after* the generate block
        -- So, pass a dummy '0' for the 'less' parameter to the function now.
        alu_bit_outputs(i) <= calculate_one_bit_alu(
            A       => A(i),
            B       => B(i),
            less    => '0', -- Pass placeholder '0', final SLT computed later
            carryin => INTERNAL_CARRY(i),
            opcode  => Opcode
        );

        -- Concurrent assignments to extract intermediate results
        Result_Internal(i) <= alu_bit_outputs(i).res;
        INTERNAL_SET(i)    <= alu_bit_outputs(i).s;       -- Captures the raw sum bit (sign bit at i=6)
        INTERNAL_CARRY(i+1)<= alu_bit_outputs(i).cout;    -- Captures the carry chain

    END GENERATE ALU_CALC_GEN;

    -- *** Calculate Corrected SLT Result ***

    -- 1. Get the raw sign bit from the MSB's adder sum (captured in INTERNAL_SET(6))
    sign_bit_msb <= Result_Internal(6); -- This is Sum(6) when opcode is SLT/SUB

    -- 2. Calculate Overflow for the SLT/SUB operation
    --    Overflow = CarryIn_MSB XOR CarryOut_MSB
    overflow_slt <= INTERNAL_CARRY(6) XOR INTERNAL_CARRY(7) WHEN (Opcode = "0110" OR Opcode = "0111") ELSE '0';

    -- 3. Calculate the final SLT result bit (True A < B signed)
    --    Result = SignBit XOR Overflow
    final_slt_value <= sign_bit_msb XOR overflow_slt WHEN Opcode = "0111" ELSE '0';


    -- *** Determine Final Result Output based on Opcode ***
    -- Use a conditional assignment for the final Result
    WITH Opcode SELECT
        Result <= Result_Internal               WHEN "0000", -- AND
                  Result_Internal               WHEN "0001", -- OR
                  Result_Internal               WHEN "0010", -- ADD
                  Result_Internal               WHEN "0110", -- SUB
                  "000000" & final_slt_value   WHEN "0111", -- SLT (Use corrected value)
                  Result_Internal               WHEN "1100", -- NOR
                  (OTHERS => '0')               WHEN OTHERS; -- Default


    -- Prepare inputs for the 7-Segment Decoders (Based on the final 'Result' signal)
    hex0_input <= Result(3 DOWNTO 0);
    hex1_input <= "0" & Result(6 DOWNTO 4);

    -- Call the 7-Segment function from the package
    HEX0 <= bin_to_7seg_active_low(hex0_input);
    HEX1 <= bin_to_7seg_active_low(hex1_input);

END ARCHITECTURE Structural;