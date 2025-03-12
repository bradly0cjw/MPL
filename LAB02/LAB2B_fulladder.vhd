LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;

ENTITY fulladd IS
PORT(
	cin,x,y : in std_logic;
	s,Cout : out std_logic);
END fulladd;

ARCHITECTURE func OF fulladd IS
BEGIN
	s<= x xor y xor cin;
	Cout <= (x and y) or (Cin and x) or (Cin and y);
END func;