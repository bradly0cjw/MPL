library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity FSM is
    port (
    c1k, reset, w : in std_logic;
    output: out std_logic_vector(2 downto 0)
    );
end;

architecture logicFun of FSM is
    signal state, next_state: std_logic_vector(2 downto 0) := "000";
begin
    process (state, c1k, reset)
    begin
        if reset = '1' then
            next_state <= "000";
        elsif rising_edge(c1k) then
            case state is
                when "000" =>
                    if w = '1' then
                        next_state <= "001";
                    else
                        next_state <= "000";
                    end if;
                when "001" =>
                    if w = '1' then
                        next_state <= "011";
                    else
                        next_state <= "010";
                    end if;
                when "010" =>
                    next_state <= "100";
                when "011" =>
                    next_state <= "100";
                when "100" =>
                    if w = '1' then
                        next_state <= "101";
                    else
                        next_state <= "000";
                    end if;

                when others =>
                    next_state <= "000";
            end case;
        end if;
    end process;
    
    state <= next_state;
    
    process (state)
    begin
        case state is
            when "000" =>
                output <= "000";
            when "001" =>
                output <= "001";
            when "010" =>
                output <= "010";
            when "011" =>
                output <= "011";
            when "100" =>
                output <= "100";
            when "101" =>
                output <= "101";
            when others =>
                output <= "000";
        end case;
    end process;

end;