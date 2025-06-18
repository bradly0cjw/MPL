library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Using numeric_std is generally preferred over std_logic_unsigned

entity lab05a is
    generic (N : integer := 8); -- Default N to 8, will be overridden by instantiation
    port(
        clk    : in  std_logic;
        clear  : in  std_logic;
        load   : in  std_logic;     -- '1' to load di, '0' to shift
        lr_sel : in  std_logic;     -- '1' for left shift, '0' for right shift
        di     : in  std_logic_vector(N-1 downto 0);
        sdi    : in  std_logic;     -- Serial data input
        qo     : out std_logic_vector(N-1 downto 0)
    );
end lab05a;

architecture behavior of lab05a is
    signal q_reg : std_logic_vector(N-1 downto 0) := (others => '0');
begin
    process(clk, clear)
    begin
        if clear = '1' then
            q_reg <= (others => '0');
        elsif rising_edge(clk) then
            if load = '1' then
                q_reg <= di;
            else -- Shift operation (load = '0')
                if lr_sel = '1' then -- Left Shift
                    q_reg <= q_reg(N-2 downto 0) & sdi; -- sdi becomes new LSB q_reg(0), q_reg(N-1) is shifted out
                else -- Right Shift (lr_sel = '0')
                    q_reg <= sdi & q_reg(N-1 downto 1); -- sdi becomes new MSB q_reg(N-1), q_reg(0) is shifted out
                end if;
            end if;
        end if;
    end process;

    qo <= q_reg;
end behavior;