LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
package LAB2B_package IS
	component fulladd
	PORT ( Cin,x,y: IN STD_LOGIC ;
			s,Cout : OUT STD_LOGIC );
	END component fulladd;
	
	component hex
		port(w1,x1,y1,z1,w2,x2,y2,z2: in std_logic;
		a1,b1,c1,d1,e1,f1,g1,a2,b2,c2,d2,e2,f2,g2: out std_logic);
	End component hex;
	
END LAB2B_package;