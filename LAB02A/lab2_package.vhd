LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;

package lab2_package is
	component fulladder
		port( cin , x, y: in std_logic ;
				s, cout : out std_logic);
	end component fulladder;
	
	component hex
		port (w1, x1, y1, z1, w2, x2, y2, z2: in std_logic;
				a1,b1,c1,d1,e1,f1,g1,a2,b2,c2,d2,e2,f2,g2: out std_logic);
	END component hex;
END lab2_package;