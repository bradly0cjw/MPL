LIBRARY ieee;
USE ieee.std_logic_1164.all;

--=============================================================================
-- Package Declaration: Defines the interface for the 7-Segment utilities
--=============================================================================
PACKAGE SevenSegment_Pkg IS

    -- *** FIX: Declare a subtype for the constrained vector ***
    SUBTYPE type_7SegmentVector IS STD_LOGIC_VECTOR(6 DOWNTO 0);

    -- Function to convert 4-bit binary to active-low 7-segment pattern
    FUNCTION bin_to_7seg_active_low (
        bin_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
    -- *** FIX: Use the declared subtype as the return type ***
    ) RETURN type_7SegmentVector;

END PACKAGE SevenSegment_Pkg;

--=============================================================================
-- Package Body: Contains the implementation of the declared functions
--=============================================================================
PACKAGE BODY SevenSegment_Pkg IS

    -- Implementation of the conversion function
    FUNCTION bin_to_7seg_active_low (
        bin_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
    -- *** FIX: Use the subtype here as well ***
    ) RETURN type_7SegmentVector IS
        -- Use the subtype for the internal variable too (good practice)
        VARIABLE seg_out_var : type_7SegmentVector;
    BEGIN
        -- Use CASE statement instead of WITH SELECT in function body
        CASE bin_in IS
            --          abcdefg (active low)
            WHEN "0000" => seg_out_var := "1000000"; -- 0
            WHEN "0001" => seg_out_var := "1111001"; -- 1
            WHEN "0010" => seg_out_var := "0100100"; -- 2
            WHEN "0011" => seg_out_var := "0110000"; -- 3
            WHEN "0100" => seg_out_var := "0011001"; -- 4
            WHEN "0101" => seg_out_var := "0010010"; -- 5
            WHEN "0110" => seg_out_var := "0000010"; -- 6
            WHEN "0111" => seg_out_var := "1111000"; -- 7
            WHEN "1000" => seg_out_var := "0000000"; -- 8
            WHEN "1001" => seg_out_var := "0010000"; -- 9
            WHEN "1010" => seg_out_var := "0001000"; -- A
            WHEN "1011" => seg_out_var := "0000011"; -- b
            WHEN "1100" => seg_out_var := "1000110"; -- C
            WHEN "1101" => seg_out_var := "0100001"; -- d
            WHEN "1110" => seg_out_var := "0000110"; -- E
            WHEN "1111" => seg_out_var := "0001110"; -- F
            WHEN OTHERS => seg_out_var := "1111111"; -- Off (blank)
        END CASE;
        RETURN seg_out_var; -- Return the variable
    END FUNCTION bin_to_7seg_active_low;

END PACKAGE BODY SevenSegment_Pkg;