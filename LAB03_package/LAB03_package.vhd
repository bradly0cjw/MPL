library ieee;
use ieee. std_logic_1164. all;
package LAB03_package is
	component fulladd
		port( cin, x, y : in std_logic;
				S, Cout : out std_logic);
	end component fulladd;

	component hex
		port(  w1, x1, y1, z1, w2, x2, y2, z2: in std_logic;
				a1, b1, c1, d1, e1, f1, g1, a2, b2, c2, d2, e2, f2, g2: out std_logic);
	end component hex;

	component BCD_Correction_Gate
		port( s0,s1,s2,s3: in  std_logic;
				C4       : in  std_logic;
				Corr_s0,Corr_s1,Corr_s2,Corr_s3 : out std_logic;
				Cout     : out std_logic);
	end component BCD_Correction_Gate;
end LAB03_package;