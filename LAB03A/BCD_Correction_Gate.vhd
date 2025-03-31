library ieee;
use ieee.std_logic_1164.all;

entity BCD_Correction_Gate is
  port(
    s0,s1,s2,s3: in  std_logic;
    C4       : in  std_logic;
    Corr_s0,Corr_s1,Corr_s2,Corr_s3 : out std_logic;
    Cout     : out std_logic
  );
end BCD_Correction_Gate;

architecture GateLevel of BCD_Correction_Gate is
  signal Corr : std_logic;
  signal FA0_sum, FA1_sum, FA2_sum, FA3_sum : std_logic;
  signal FA0_carry, FA1_carry, FA2_carry, FA3_carry : std_logic;
begin
  Corr <= C4 or (s3 and (s2 or s1));

  Corr_s0   <= s0 xor '0' xor '0';
  FA0_carry <= (s0 and '0') or ('0' and (s0 xor '0'));

  Corr_s1   <= s1 xor Corr xor FA0_carry;
  FA1_carry <= (s1 and Corr) or (FA0_carry and (s1 xor Corr));

  Corr_s2   <= s2 xor Corr xor FA1_carry;
  FA2_carry <= (s2 and Corr) or (FA1_carry and (s2 xor Corr));

  Corr_s3  <= s3 xor '0' xor FA2_carry;
  FA3_carry <= (s3 and '0') or (FA2_carry and (s3 xor '0'));


  Cout     <= FA3_carry;
end architecture GateLevel;
