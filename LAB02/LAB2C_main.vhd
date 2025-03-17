LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE work.LAB2B_package.all;

ENTITY LAB2C_main IS
PORT(
    A: in std_logic_vector(7 downto 0);
    B: in std_logic_vector(7 downto 0);
    -- S: out std_logic_vector(7 downto 0);
    hexo: out std_logic_vector(13 downto 0);
    n: in std_logic;
    negled: out std_logic ;
    Overflow: out std_logic	);

END LAB2C_main;


ARCHITECTURE func OF LAB2C_main IS
    SIGNAL C: std_logic_vector(8 downto 0);
    SIGNAL S: std_logic_vector(7 downto 0);
    SIGNAL F: std_logic_vector(7 downto 0);
    SIGNAL FC: std_logic_vector(7 downto 0);
    SIGNAL S_inverted: std_logic_vector(7 downto 0);
    SIGNAL add_one: std_logic;
	SIGNAL neg: std_logic;

BEGIN
    stage0: fulladd port map (C(0) or n,n xor A(0),B(0),S(0),C(1));
    stage1: fulladd port map (C(1),n xor A(1),B(1),S(1),C(2));
    stage2: fulladd port map (C(2),n xor A(2),B(2),S(2),C(3));
    stage3: fulladd port map (C(3),n xor A(3),B(3),S(3),C(4));
    stage4: fulladd port map (C(4),n xor A(4),B(4),S(4),C(5));
    stage5: fulladd port map (C(5),n xor A(5),B(5),S(5),C(6));
    stage6: fulladd port map (C(6),n xor A(6),B(6),S(6),C(7));
    stage7: fulladd port map (C(7),n xor A(7),B(7),S(7),C(8));

	neg <= S(7) and n;
    -- Invert S when negled is high
    S_inverted <= S xor (neg & neg & neg & neg & neg & neg & neg & neg);

    -- Add 1 to the inverted S if negled is high
    add_one <= neg;

    stageF0: fulladd port map (add_one, S_inverted(0), '0', F(0), FC(0));
    stageF1: fulladd port map (FC(0), S_inverted(1), '0', F(1), FC(1));
    stageF2: fulladd port map (FC(1), S_inverted(2), '0', F(2), FC(2));
    stageF3: fulladd port map (FC(2), S_inverted(3), '0', F(3), FC(3));
    stageF4: fulladd port map (FC(3), S_inverted(4), '0', F(4), FC(4));
    stageF5: fulladd port map (FC(4), S_inverted(5), '0', F(5), FC(5));
    stageF6: fulladd port map (FC(5), S_inverted(6), '0', F(6), FC(6));
    stageF7: fulladd port map (FC(6), S_inverted(7), '0', F(7), FC(7));
    
    Overflow <= (C(8) Xor S(7)); 
    negled <= neg;
    
    hexoutput: hex port map (F(3),F(2),F(1),F(0),F(7),F(6),F(5),F(4),
    hexo(0),hexo(1),hexo(2),hexo(3),hexo(4),hexo(5),hexo(6),
    hexo(7),hexo(8),hexo(9),hexo(10),hexo(11),hexo(12),hexo(13));
END func;