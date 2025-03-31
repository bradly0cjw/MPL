library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.LAB2B_package.all;

ENTITY lab03 is
port(
    A: in std_logic_vector(7 downto 0);
    B: in std_logic_vector(7 downto 0);
    hexo: out std_logic_vector(13 downto 0);
    negled: out std_logic;
    neghex: out std_logic;
    Overflow: out std_logic
    );
end lab03;

architecture func of lab03 is
    signal C: std_logic_vector(8 downto 0);
    signal S: std_logic_vector(7 downto 0);
    signal F: std_logic_vector(7 downto 0);
    signal FC: std_logic_vector(7 downto 0);
    signal Carry: std_logic;
    signal add_one: std_logic;
    signal neg: std_logic;
    signal n: std_logic;

begin
    n <= '1';
    stage0: fulladd port map (C(0) or n, n xor A(0), B(0), S(0), C(1));
    stage1: fulladd port map (C(1), n xor A(1), B(1), S(1), C(2));
    stage2: fulladd port map (C(2), n xor A(2), B(2), S(2), C(3));
    stage3: fulladd port map (C(3), n xor A(3), B(3), S(3), C(4));


    Carry <= (S(3) and S(2)) or (S(3) and S(1));
    

    stageBCD0: fulladd port map ('0', S(0), '0', F(0), FC(0));
    stageBCD1: fulladd port map (FC(0), S(1), Carry, F(1), FC(1));
    stageBCD2: fulladd port map (FC(1), S(2), Carry, F(2), FC(2));
    stageBCD3: fulladd port map (FC(2), S(3), '0', F(3), FC(3));
    