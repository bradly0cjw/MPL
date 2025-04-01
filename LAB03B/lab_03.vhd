library ieee;
use ieee.std_logic_1164. all;
use work. LAB03_package. all;

entity lab_03 is
	port( A : in std_logic_vector (7 downto 0);
		B : in std_logic_vector (7 downto 0);
		debug : out std_logic_vector (7 downto 0);
		debug2 : out std_logic_vector (7 downto 0);
		debug3 : out std_logic_vector (7 downto 0);
		debug4 : out std_logic_vector (7 downto 0);
		debug5 : out std_logic;
		a0, b0, c0, d0, e0, f0, g0 : out std_logic;
		a1, b1, c1, d1, e1, f1, g1 : out std_logic;
		overflow : out std_logic);
end lab_03;

architecture structure of lab_03 is
	signal c :std_logic_vector ( 7 downto 0);
	signal s :std_logic_vector ( 7 downto 0);
	signal Corr_s :std_logic_vector( 7 downto 0);
	signal Corr_c : std_logic_vector( 7 downto 0);
	signal Corr_s2 : std_logic_vector( 7 downto 4);
	signal Corr_c2 : std_logic_vector( 7 downto 4);
	signal temp : std_logic_vector( 2 downto 0);
	signal borrow: std_logic;
	signal borrow2: std_logic;
	signal borrow3: std_logic;
	
begin
	-- represent first digit of the BCD number
	stage0: fulladd port map( '1' , A(0), (B(0) xor '1'), s(0)  , c(0)   );
	stagel: fulladd port map( c(0), A(1), (B(1) xor '1'), s(1)  , c(1)   );
	stage2: fulladd port map( c(1), A(2), (B(2) xor '1'), s(2)  , c(2)   );
	stage3: fulladd port map( c(2), A(3), (B(3) xor '1'), s(3)  , c(3)   );
	stage3a:fulladd port map( c(3), '0' , ('0'  xor '1'), borrow, temp(0));
	
	-- represent second digit of the BCD number
	stage4: fulladd port map( '1' , A(4), (B(4) xor '1'), s(4)   , c(4)   );
	stage5: fulladd port map( c(4), A(5), (B(5) xor '1'), s(5)   , c(5)   );
	stage6: fulladd port map( c(5), A(6), (B(6) xor '1'), s(6)   , c(6)   );
	stage7: fulladd port map( c(6), A(7), (B(7) xor '1'), s(7)   , c(7)   );
	stage7a:fulladd port map( c(7), '0' , ('0'  xor '1'), borrow2, temp(1));
	
	-- borrow <= (s(2) or s(1) or s(0)) and s(3);
	debug5 <= borrow;

	correction0: fulladd port map( '0'      , s(0), '0'   , Corr_s(0), Corr_c(0));
	correction1: fulladd port map( Corr_c(0), s(1), borrow, Corr_s(1), Corr_c(1));
	correction2: fulladd port map( Corr_c(1), s(2), '0'   , Corr_s(2), Corr_c(2));
	correction3: fulladd port map( Corr_c(2), s(3), borrow, Corr_s(3), Corr_c(3));

	correction4: fulladd port map( '0'      , s(4), borrow, Corr_s(4), Corr_c(4));
	correction5: fulladd port map( Corr_c(4), s(5), borrow, Corr_s(5), Corr_c(5));
	correction6: fulladd port map( Corr_c(5), s(6), borrow, Corr_s(6), Corr_c(6));
	correction7: fulladd port map( Corr_c(6), s(7), borrow, Corr_s(7), Corr_c(7));
	correction7a:fulladd port map( Corr_c(7), '0' , borrow, borrow3  , temp(2)  );

	-- Corr_borrow <= (Corr_s(6) or Corr_s(5) or Corr_s(4)) and Corr_s(7);
	
	correction8 : fulladd port map( '0'       , Corr_s(4), '0'               , Corr_s2(4), Corr_c2(4));
	correction9 : fulladd port map( Corr_c2(4), Corr_s(5), borrow2 or borrow3, Corr_s2(5), Corr_c2(5));
	correction10: fulladd port map( Corr_c2(5), Corr_s(6), '0'               , Corr_s2(6), Corr_c2(6));
	correction11: fulladd port map( Corr_c2(6), Corr_s(7), borrow2 or borrow3, Corr_s2(7), Corr_c2(7));
	
	debug <= s;
	debug2 <= c;
	debug3 <= Corr_s2(7) & Corr_s2(6) & Corr_s2(5) & Corr_s2(4) & Corr_s(3) & Corr_s(2) & Corr_s(1) & Corr_s(0);
	debug4 <= Corr_c2(7) & Corr_c2(6) & Corr_c2(5) & Corr_c2(4) & Corr_c(3) & Corr_c(2) & Corr_c(1) & Corr_c(0);
	
	overflow <= borrow2 or borrow3;

	-- underflow

	hex0 : hex port map ( Corr_s(3), Corr_s(2), Corr_s(1), Corr_s(0),
	Corr_s2(7), Corr_s2(6), Corr_s2(5), Corr_s2(4),
	a0,b0,c0,d0,e0,f0,g0,a1,b1,c1,d1,e1,f1,g1);
	
end structure;
	