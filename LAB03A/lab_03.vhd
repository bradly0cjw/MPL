library ieee;
use ieee.std_logic_1164. all;
use work. LAB03_package. all;

entity lab_03 is
	port( A : in std_logic_vector (0 to 7);
		B : in std_logic_vector (0 to 7);
		a0, b0, c0, d0, e0, f0, g0 : out std_logic;
		a1, b1, c1, d1, e1, f1, g1 : out std_logic;
		overflow : out std_logic);
end lab_03;

architecture structure of lab_03 is
	signal c :std_logic_vector ( 7 downto 0);
	signal s :std_logic_vector ( 7 downto 0);
	signal Corr_s :std_logic_vector( 7 downto 0);
	signal cout: std_logic_vector( 1 downto 0 );
	
begin
	stage0: fulladd port map(A(0), B(0), '0', s(0), c(1));
	stagel: fulladd port map(A(1), B(1), c(1), s(1), c(2));
	stage2: fulladd port map(A(2), B(2), c(2), s(2), c(3));
	stage3: fulladd port map(A(3), B(3), c(3), s(3), c(4));
	
	adj0:	BCD_Correction_Gate port map( s(0), s(1), s(2), s(3), c(4),
													Corr_s(0),Corr_s(1),Corr_s(2),Corr_s(3),cout(0));
	stage4: fulladd port map(A(4), B(4), cout(0), s(4), c(5));
	stage5: fulladd port map(A(5), B(5), c(5), s(5), c(6));
	stage6: fulladd port map(A(6), B(6), c(6), s(6), c(7));
	stage7: fulladd port map(A(7), B(7), c(7), s(7), cout(1));
	adj1:	BCD_Correction_Gate port map( s(4), s(5), s(6), s(7), cout(1),
													Corr_s(4),Corr_s(5),Corr_s(6),Corr_s(7),overflow);
	hex0 : hex port map ( Corr_s(3), Corr_s(2), Corr_s(1), Corr_s(0),Corr_s(7), Corr_s(6), Corr_s(5), Corr_s(4)
								,a0,b0,c0,d0,e0,f0,g0,a1,b1,c1,d1,e1,f1,g1);
	end structure;
	