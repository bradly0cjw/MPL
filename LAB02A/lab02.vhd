LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
use work.lab2_package.all;

entity lab02 is 
port (
	a : in std_logic_vector( 7 downto 0);
	b : in std_logic_vector( 7 downto 0);
	cout : out std_logic;
	a1,b1,c1,d1,e1,f1,g1,a2,b2,c2,d2,e2,f2,g2: out std_logic);
end lab02;

architecture f of lab02 is
	signal c : std_logic_vector( 7 downto 0);
	signal s : std_logic_vector( 7 downto 0);
begin
	stage0: fulladder port map (c(0),a(0), b(0), s(0),c(1));
	stage1: fulladder port map (c(1),a(1), b(1), s(1),c(2));
	stage2: fulladder port map (c(2),a(2), b(2), s(2),c(3));
	stage3: fulladder port map (c(3),a(3), b(3), s(3),c(4));
	stage4: fulladder port map (c(4),a(4), b(4), s(4),c(5));
	stage5: fulladder port map (c(5),a(5), b(5), s(5),c(6));
	stage6: fulladder port map (c(6),a(6), b(6), s(6),c(7));
	stage7: fulladder port map (c(7),a(7), b(7), s(7),cout);
	hex0 : hex port map ( s(3), s(2), s(1), s(0),s(7), s(6), s(5), s(4),a1,b1,c1,d1,e1,f1,g1,a2,b2,c2,d2,e2,f2,g2);
end f;