library ieee;
use ieee.std_logic_1164.all;
entity fulladder is
	port( cin, x,y : in std_logic;
	s, Cout : out std_logic);
end fulladder;

architecture func of fulladder is
	begin
	s <= x xor y xor cin;
	Cout <= (x and y) or (cin and x) or (cin and y);
end func;