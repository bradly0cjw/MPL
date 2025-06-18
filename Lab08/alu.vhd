LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY alu IS
    PORT (
        operand_a : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        operand_b : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        alu_op    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        result    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END alu;

ARCHITECTURE behavioral OF alu IS
    SIGNAL comp_result : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
    PROCESS (operand_a, operand_b, alu_op)
    BEGIN
        CASE alu_op IS
            WHEN "000" => -- ADD
                result <= std_logic_vector(unsigned(operand_a) + unsigned(operand_b));
            WHEN "001" => -- AND
                result <= operand_a AND operand_b;
            WHEN "010" => -- SUB(A-B)  (Rs - Rt)
                result <= std_logic_vector(unsigned(operand_a) - unsigned(operand_b));
            WHEN "011" => -- SLT (Set on Less Than)
                IF signed(operand_a) < signed(operand_b) THEN
                    result <= x"01";
                ELSE
                    result <= x"00";
                END IF;
            WHEN "100" => -- SUB(B-A) (Rt - Rs)
                result <= std_logic_vector(unsigned(operand_b) - unsigned(operand_a));
            WHEN OTHERS =>
                result <= (OTHERS => 'X'); -- Default/unused case
        END CASE;
    END PROCESS;
END behavioral;