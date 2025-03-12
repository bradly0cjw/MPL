LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE work.LAB2B_package.all;

ENTITY LAB2B_main IS
PORT(
	A: in std_logic_vector(7 downto 0);
	B: in std_logic_vector(7 downto 0);
	-- S: out std_logic_vector(7 downto 0);
	hexo: out std_logic_vector(13 downto 0);
	n: in std_logic;
	Cout: out std_logic	);

END LAB2B_main;


ARCHITECTURE func OF LAB2B_main IS
	SIGNAL C: std_logic_vector(7 downto 0);
	SIGNAL S: std_logic_vector(7 downto 0);
	SIGNAL C8: std_logic;

BEGIN
	stage0: fulladd port map (C(0) or n,n xor A(0),B(0),S(0),C(1));
	stage1: fulladd port map (C(1),n xor A(1),B(1),S(1),C(2));
	stage2: fulladd port map (C(2),n xor A(2),B(2),S(2),C(3));
	stage3: fulladd port map (C(3),n xor A(3),B(3),S(3),C(4));
	stage4: fulladd port map (C(4),n xor A(4),B(4),S(4),C(5));
	stage5: fulladd port map (C(5),n xor A(5),B(5),S(5),C(6));
	stage6: fulladd port map (C(6),n xor A(6),B(6),S(6),C(7));
	stage7: fulladd port map (C(7),n xor A(7),B(7),S(7),C8);
	Cout <= ((C8 xor C(7)) and n) or (C8 and not n);
	hexoutput: hex port map (S(3),S(2),S(1),S(0),S(7),S(6),S(5),S(4),
	hexo(0),hexo(1),hexo(2),hexo(3),hexo(4),hexo(5),hexo(6),
	hexo(7),hexo(8),hexo(9),hexo(10),hexo(11),hexo(12),hexo(13));
END func;
