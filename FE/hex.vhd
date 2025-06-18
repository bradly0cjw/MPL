library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Not strictly needed for this hex conversion, but good practice

-- Entity for 16-bit binary to 4-digit hexadecimal 7-segment display driver
entity binary_to_4_digit_7seg is
    port (
        binary_in         : in  std_logic_vector(15 downto 0); -- 16-bit binary input (0000-FFFF)
        segments_out_d0   : out std_logic_vector(6 downto 0);  -- 7-segment for Hex Digit 0 (LSN)
        segments_out_d1   : out std_logic_vector(6 downto 0);  -- 7-segment for Hex Digit 1
        segments_out_d2   : out std_logic_vector(6 downto 0);  -- 7-segment for Hex Digit 2
        segments_out_d3   : out std_logic_vector(6 downto 0)   -- 7-segment for Hex Digit 3 (MSN)
    );
end entity binary_to_4_digit_7seg;

architecture behavioral of binary_to_4_digit_7seg is

    -- Internal signals for the four 4-bit hex nibbles
    signal hex_nibble_d0 : std_logic_vector(3 downto 0); -- Hex Digit 0 (bits 3-0 of input)
    signal hex_nibble_d1 : std_logic_vector(3 downto 0); -- Hex Digit 1 (bits 7-4 of input)
    signal hex_nibble_d2 : std_logic_vector(3 downto 0); -- Hex Digit 2 (bits 11-8 of input)
    signal hex_nibble_d3 : std_logic_vector(3 downto 0); -- Hex Digit 3 (bits 15-12 of input)

    -- Reusable function for 4-bit Hex Nibble to 7-segment conversion
    -- (Assumes common anode display: '0' = segment ON, '1' = segment OFF)
    function hex_nibble_to_segments_func(hex_val : std_logic_vector(3 downto 0)) return std_logic_vector is
        variable segments : std_logic_vector(6 downto 0); -- g f e d c b a
    begin
        case hex_val is
            WHEN "0000" => segments := "1000000"; -- 0
            WHEN "0001" => segments := "1111001"; -- 1
            WHEN "0010" => segments := "0100100"; -- 2
            WHEN "0011" => segments := "0110000"; -- 3
            WHEN "0100" => segments := "0011001"; -- 4
            WHEN "0101" => segments := "0010010"; -- 5
            WHEN "0110" => segments := "0000010"; -- 6
            WHEN "0111" => segments := "1111000"; -- 7
            WHEN "1000" => segments := "0000000"; -- 8
            WHEN "1001" => segments := "0010000"; -- 9
            WHEN "1010" => segments := "0001000"; -- A
            WHEN "1011" => segments := "0000011"; -- b (lowercase for distinctness from 8)
            WHEN "1100" => segments := "1000110"; -- C (uppercase) or "0100111" for c (lowercase)
            WHEN "1101" => segments := "0100001"; -- d (lowercase for distinctness from 0)
            WHEN "1110" => segments := "0000110"; -- E (uppercase)
            WHEN "1111" => segments := "0001110"; -- F (uppercase)
            WHEN OTHERS => segments := "1111111"; -- All segments OFF (blank)
        end case;
        return segments;
    end function hex_nibble_to_segments_func;

begin

    -- Process to split 16-bit binary input into four 4-bit hex nibbles
    -- This is purely combinational logic, so a process is not strictly
    -- necessary for just slicing, but it's fine.
    -- Alternatively, can be done with concurrent signal assignments.
    process(binary_in)
    begin
        hex_nibble_d0 <= binary_in(3 downto 0);   -- Least Significant Nibble (LSN)
        hex_nibble_d1 <= binary_in(7 downto 4);
        hex_nibble_d2 <= binary_in(11 downto 8);
        hex_nibble_d3 <= binary_in(15 downto 12); -- Most Significant Nibble (MSN)
    end process;

    -- Convert each 4-bit hex nibble to its 7-segment representation
    segments_out_d0 <= hex_nibble_to_segments_func(hex_nibble_d0); -- Display LSN on d0
    segments_out_d1 <= hex_nibble_to_segments_func(hex_nibble_d1);
    segments_out_d2 <= hex_nibble_to_segments_func(hex_nibble_d2);
    segments_out_d3 <= hex_nibble_to_segments_func(hex_nibble_d3); -- Display MSN on d3

end architecture behavioral;