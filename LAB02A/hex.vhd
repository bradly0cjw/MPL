LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;

entity hex is
port (
 w1, x1, y1, z1, w2, x2, y2, z2: in bit;
 a1, b1, c1, d1, e1, f1, g1, a2, b2, c2, d2, e2, f2, g2: out bit);
end hex;
architecture func of hex is
begin
 a1 <= (x1 and not y1 and not z1) or (w1 and x1 and not y1) or (not
w1 and not x1 and not y1 and z1 ) or ( w1 and not x1 and y1 and z1 );
 b1 <= (w1 and y1 and z1) or (w1 and x1 and y1) or (x1 and y1 and
not z1) or (w1 and x1 and not z1) or ( not w1 and x1 and not y1 and
z1);
 c1 <= ( not w1 and not x1 and y1 and not z1) or ( w1 and x1 and not
z1) or ( w1 and x1 and y1);
 d1 <= ( not x1 and not y1 and z1) or ( not w1 and x1 and not y1 and
not z1) or ( x1 and y1 and z1) or ( w1 and not x1 and y1 and not z1);
 e1 <= (not w1 and z1) or (not w1 and x1 and not y1) or (not x1 and
not y1 and z1);
 f1 <= (not w1 and not x1 and z1) or (not w1 and not x1 and y1) or
(not w1 and y1 and z1) or (w1 and x1 and not y1);
 g1 <= (not w1 and not x1 and not y1) or (not w1 and x1 and y1 and
z1);
 a2 <= (x2 and not y2 and not z2) or (w2 and x2 and not y2) or (not
w2 and not x2 and not y2 and z2 ) or ( w2 and not x2 and y2 and z2 );
 b2 <= (w2 and y2 and z2) or (w2 and x2 and y2) or (x2 and y2 and
not z2) or (w2 and x2 and not z2) or ( not w2 and x2 and not y2 and
z2);
 c2 <= ( not w2 and not x2 and y2 and not z2) or ( w2 and x2 and not
z2) or ( w2 and x2 and y2);
 d2 <= ( not x2 and not y2 and z2) or ( not w2 and x2 and not y2 and
not z2) or ( x2 and y2 and z2) or ( w2 and not x2 and y2 and not z2);
 e2 <= (not w2 and z2) or (not w2 and x2 and not y2) or (not x2 and
not y2 and z2);
 f2 <= (not w2 and not x2 and z2) or (not w2 and not x2 and y2) or
(not w2 and y2 and z2) or (w2 and x2 and not y2);
 g2 <= (not w2 and not x2 and not y2) or (not w2 and x2 and y2 and
z2);
end func; 