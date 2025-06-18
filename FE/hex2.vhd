library ieee;
use ieee.std_logic_1164.all;

entity hex is 
port( com_in: in std_logic_vector(3 downto 0);
		com_out: out std_logic_vector(6 downto 0));
end hex;

architecture func of hex is
begin
		com_out(0) <=  ((not com_in(3)) and (not com_in(2)) and (not com_in(1))  and (com_in(0))) or ((not com_in(3)) and (com_in(2)) and (not com_in(1))  and (not com_in(0)))  or ((com_in(3)) and (not com_in(2)) and (com_in(1))  and (com_in(0))) or ((com_in(3)) and (com_in(2)) and (not com_in(1))  and (not com_in(0))) or ((com_in(3)) and (com_in(2)) and (not com_in(1))  and (com_in(0)));
		com_out(1) <=  ((not com_in(3)) and (com_in(2)) and (not com_in(1))  and (com_in(0))) or ((not com_in(3)) and (com_in(2)) and (com_in(1))  and (not com_in(0)))  or ((com_in(3)) and (not com_in(2)) and (com_in(1))  and (com_in(0))) or ((com_in(3)) and (com_in(2)) and (not com_in(1))  and (not com_in(0))) or ((com_in(3)) and (com_in(2)) and (com_in(1))  and (not com_in(0))) or ((com_in(3)) and (com_in(2)) and (com_in(1))  and (com_in(0)));
		com_out(2) <=  ((not com_in(3)) and (not com_in(2)) and (com_in(1))  and (not com_in(0))) or ((com_in(3)) and (com_in(2)) and (not com_in(0))) or ((com_in(3)) and (com_in(2)) and (com_in(1)));
		com_out(3) <=  ((not com_in(2)) and (not com_in(1))  and (com_in(0))) or ((not com_in(3)) and (com_in(2)) and (not com_in(1))  and (not com_in(0))) or ((com_in(2)) and (com_in(1))  and (com_in(0))) or ((com_in(3)) and (not com_in(2)) and (com_in(1))  and (not com_in(0)));
		com_out(4) <=  ((not com_in(3)) and (com_in(0))) or ((not com_in(3)) and (com_in(2)) and (not com_in(1))) or ((not com_in(2)) and (not com_in(1))  and (com_in(0)));
		com_out(5) <=  ((not com_in(3)) and (not com_in(2)) and (com_in(0))) or ((not com_in(3)) and (not com_in(2)) and (com_in(1))) or ((not com_in(3)) and (com_in(1))  and (com_in(0))) or ((com_in(3)) and (com_in(2)) and (not com_in(1)));
		com_out(6) <=  ((not com_in(3)) and (not com_in(2)) and (not com_in(1))) or ((not com_in(3)) and (com_in(2)) and (com_in(1))  and (com_in(0)));
		
END func;
