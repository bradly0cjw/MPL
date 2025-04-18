LIBRARY ieee;
USE ieee.std_logic_1164.all;

--=============================================================================
-- Package Declaration: Defines types and functions for the 1-bit ALU logic
--=============================================================================
PACKAGE AluBit_Pkg IS

    -- Define a record type to hold the multiple outputs of the 1-bit ALU function
    TYPE type_OneBitAluResult IS RECORD
        res  : STD_LOGIC; -- Result bit
        s    : STD_LOGIC; -- Set bit (for SLT)
        cout : STD_LOGIC; -- Carry Out bit
    END RECORD type_OneBitAluResult;

    -- Function to perform the 1-bit ALU operation
    FUNCTION calculate_one_bit_alu (
        -- Inputs
        A       : IN STD_LOGIC;
        B       : IN STD_LOGIC;
        less    : IN STD_LOGIC;
        carryin : IN STD_LOGIC;
        opcode  : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
    ) RETURN type_OneBitAluResult;

END PACKAGE AluBit_Pkg;

--=============================================================================
-- Package Body: Implementation of the 1-bit ALU function
--=============================================================================

PACKAGE BODY AluBit_Pkg IS

    FUNCTION calculate_one_bit_alu (
        -- Inputs
        A       : IN STD_LOGIC;
        B       : IN STD_LOGIC;
        less    : IN STD_LOGIC; -- This input is now effectively ignored by the corrected top-level
        carryin : IN STD_LOGIC;
        opcode  : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
    ) RETURN type_OneBitAluResult IS

        -- Use Variables inside the function for intermediate calculations
        VARIABLE v_result       : STD_LOGIC;
        VARIABLE v_set          : STD_LOGIC; -- Represents the raw sum bit for arithmetic ops
        VARIABLE v_carryout     : STD_LOGIC;
        VARIABLE v_b_inverted   : STD_LOGIC;
        VARIABLE v_adder_b_input: STD_LOGIC;
        VARIABLE v_adder_cin    : STD_LOGIC;
        VARIABLE v_adder_sum    : STD_LOGIC;
        VARIABLE v_adder_carry  : STD_LOGIC;
        VARIABLE v_and_result   : STD_LOGIC;
        VARIABLE v_or_result    : STD_LOGIC;
        VARIABLE v_nor_result   : STD_LOGIC;
        VARIABLE v_output_record: type_OneBitAluResult; -- Record to hold the results

    BEGIN
        -- Determine B input for adder (inverted for SUB/SLT)
        v_b_inverted    := NOT B;
        IF (opcode = "0110" OR opcode = "0111") THEN
            v_adder_b_input := v_b_inverted;
        ELSE
            v_adder_b_input := B;
        END IF;

        -- Determine Carry-In for adder (forced to '1' for SUB/SLT)
        --IF (opcode = "0110" OR opcode = "0111") THEN
        --    v_adder_cin := '1';
        --ELSE
        v_adder_cin := carryin;
        --END IF;

        -- 1. AND Operation
        v_and_result := A AND B;

        -- 2. OR Operation
        v_or_result  := A OR B;

        -- 3. Full Adder Logic (for ADD, SUB, SLT)
        v_adder_sum   := (A XOR v_adder_b_input) XOR v_adder_cin;
        -- 修正後的進位計算:
		  v_adder_carry := (A AND v_adder_b_input) OR (A AND v_adder_cin) OR (v_adder_b_input AND v_adder_cin);

        -- 4. NOR Operation
        v_nor_result := A NOR B;

        -- *** FIX: Calculate v_set (raw sum) for ALL arithmetic operations ***
        -- The top-level module needs this raw sum bit (especially from MSB)
        -- to calculate the sign bit for SLT.
        IF (opcode = "0010" OR opcode = "0110" OR opcode = "0111") THEN
            v_set := v_adder_sum;
        ELSE
            v_set := '0'; -- Set is '0' for logical operations
        END IF;

        -- 6. Select preliminary v_result based on Opcode
        --    NOTE: For SLT(0111), this v_result is ignored by the corrected top-level,
        --          which calculates the final SLT result externally.
        CASE opcode IS
            WHEN "0000" => v_result := v_and_result; -- AND
            WHEN "0001" => v_result := v_or_result;  -- OR
            WHEN "0010" => v_result := v_adder_sum;  -- ADD
            WHEN "0110" => v_result := v_adder_sum;  -- SUB
            WHEN "0111" => v_result := v_adder_sum;  -- SLT: Use adder_sum as preliminary result
                                                     -- (or could be '0', doesn't matter as top level overwrites)
            WHEN "1100" => v_result := v_nor_result; -- NOR
            WHEN OTHERS => v_result := '0';          -- Default/Undefined
        END CASE;

        -- 7. Calculate Final Carry Out (only for arithmetic ops)
        IF (opcode = "0010" OR opcode = "0110" OR opcode = "0111") THEN
            v_carryout := v_adder_carry;
        ELSE
            v_carryout := '0';
        END IF;

        -- 8. Populate the return record
        v_output_record.res  := v_result;  -- Preliminary result bit
        v_output_record.s    := v_set;     -- Raw sum bit for arithmetic ops
        v_output_record.cout := v_carryout;-- Carry out bit

        -- Return the record containing all results
        RETURN v_output_record;

    END FUNCTION calculate_one_bit_alu;

END PACKAGE BODY AluBit_Pkg;