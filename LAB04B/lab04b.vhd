LIBRARY ieee;
USE ieee.std_logic_1164.all;
use lab4a.vhdl.all; -- Include the onebitALU component

-- Entity definition for the 7-bit ALU (based on Slide 25)
ENTITY sevenBitALU IS
    PORT (
        A        : IN  STD_LOGIC_VECTOR(6 DOWNTO 0); -- 7-bit Input A
        B        : IN  STD_LOGIC_VECTOR(6 DOWNTO 0); -- 7-bit Input B
        Opcode   : IN  STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit Operation Code
        Result   : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- 7-bit Result
        CarryOut : OUT STD_LOGIC;                    -- Final Carry Out (from MSB)
        Zero     : OUT STD_LOGIC;                    -- Zero flag (Result = 0)
        Overflow : OUT STD_LOGIC                     -- Overflow flag (for signed Add/Sub)
        
    );
END ENTITY sevenBitALU;

ARCHITECTURE structural OF sevenBitALU IS

    -- Component declaration for the 1-bit ALU
    COMPONENT onebitALU IS
        PORT (
            A        : IN  STD_LOGIC;
            B        : IN  STD_LOGIC;
            less     : IN  STD_LOGIC;
            carryin  : IN  STD_LOGIC;
            opcode   : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            result   : OUT STD_LOGIC;
            set      : OUT STD_LOGIC;
            carryout : OUT STD_LOGIC
        );
    END COMPONENT onebitALU;

    -- Internal signals
    SIGNAL carries         : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Carry signals between bits (carries(0) is Cin to bit 0)
    SIGNAL set_outputs     : STD_LOGIC_VECTOR(6 DOWNTO 0); -- Set outputs from each bit (only set_outputs(6) is used)
    SIGNAL internal_result : STD_LOGIC_VECTOR(6 DOWNTO 0); -- Internal result before assigning to output port

BEGIN

    -- Determine initial CarryIn (carries(0)) based on Opcode (Slide 13)
    -- Cin = 1 for SUB ("0110") and SLT ("0111"), else 0
    carries(0) <= '1' WHEN Opcode = "0110" OR Opcode = "0111" ELSE '0';

    -- Instantiate 7 one-bit ALUs using FOR GENERATE (Slide 20, 25)
    ALU_Generate: FOR i IN 0 TO 6 GENERATE

        -- LSB (Bit 0) - Special 'less' input connection (Slide 19)
        LSB_Generate: IF i = 0 GENERATE
            onebit_alu_inst: COMPONENT onebitALU
                PORT MAP (
                    A        => A(i),
                    B        => B(i),
                    less     => set_outputs(6), -- Connect 'less' input to 'set' output of MSB (bit 6)
                    carryin  => carries(i),     -- Use initial carry carries(0)
                    opcode   => Opcode,
                    result   => internal_result(i),
                    set      => set_outputs(i), -- Generate set output (not used externally for LSB)
                    carryout => carries(i+1)    -- Output carry to next stage
                );
        END GENERATE LSB_Generate;

        -- Intermediate Bits (Bits 1 to 5) - 'less' input is '0' (Slide 19)
        MID_Generate: IF i > 0 AND i < 6 GENERATE
            onebit_alu_inst: COMPONENT onebitALU
                PORT MAP (
                    A        => A(i),
                    B        => B(i),
                    less     => '0',            -- 'less' input is always '0' for intermediate bits
                    carryin  => carries(i),     -- Input carry from previous stage
                    opcode   => Opcode,
                    result   => internal_result(i),
                    set      => set_outputs(i), -- Generate set output (not used externally)
                    carryout => carries(i+1)    -- Output carry to next stage
                );
        END GENERATE MID_Generate;

        -- MSB (Bit 6) - Special 'set' output usage, 'less' input is '0' (Slide 19)
        MSB_Generate: IF i = 6 GENERATE
            onebit_alu_inst: COMPONENT onebitALU
                PORT MAP (
                    A        => A(i),
                    B        => B(i),
                    less     => '0',            -- 'less' input is always '0' for MSB
                    carryin  => carries(i),     -- Input carry from previous stage
                    opcode   => Opcode,
                    result   => internal_result(i),
                    set      => set_outputs(i), -- Generate the final 'set' output fed back to LSB
                    carryout => carries(i+1)    -- Output final carry carries(7)
                );
        END GENERATE MSB_Generate;

    END GENERATE ALU_Generate;

    -- Assign final outputs
    Result <= internal_result;

    -- Final CarryOut is the carry from the MSB (bit 6)
    CarryOut <= carries(7);

    -- Zero Flag: NOR reduction of the result bits
    Zero <= '1' WHEN internal_result = "0000000" ELSE '0';

    -- Overflow Flag (for signed ADD/SUB/SLT - Slide 17 hint)
    -- Overflow = CarryIn to MSB XOR CarryOut from MSB
    Overflow <= carries(6) XOR carries(7) WHEN Opcode = "0010" OR Opcode = "0110" OR Opcode = "0111" ELSE
                '0'; -- Overflow only defined for Add/Sub/SLT

END ARCHITECTURE structural;