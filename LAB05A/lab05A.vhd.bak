library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- 8bit left shift register with parallel load and reset
entity lab05a is
generic (N : integer := 8);
    port(
        clk: in std_logic;
        clear: in std_logic;
        load: in std_logic;
        lr_sel : in std_logic;
        di : in std_logic_vector(N-1 downto 0);
        sdi : in std_logic;
        qo: out std_logic_vector(N-1 downto 0);
        bc: in std_logic
    );
end lab05a;

architecture behavior of lab05a is
    signal q: std_logic_vector(N-1 downto 0) := (others => '0');
begin
    process(clk, clear)
    begin
        if clear = '1' then
            q <= (others => '0');
        elsif rising_edge(clk) then
            if load = '1' then
                q <= di;
            elsif lr_sel = '1' then
            --     q <= q(N-2 downto 0) & sdi;
            -- else
            --     q <= q(N-1 downto 1) & '0';
            for i in 0 to N-2 loop
                q(i) <= q(i+1);
            end loop;
            q(N-1) <= sdi;
        else
            for i in N-1 downto 1 loop
                q(i) <= q(i-1);
            end loop;
            q(0) <= sdi;
            end if;
        end if;
    end process;
    qo <= q;
end behavior;