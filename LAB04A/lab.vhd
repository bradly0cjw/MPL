LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.SevenSegment_Pkg.all; -- 使用 7 段顯示器封裝
USE work.AluBit_Pkg.all;       -- 使用 1 位元 ALU 封裝

-- 頂層實體
ENTITY lab IS
    PORT (
        -- Inputs from Switches
        A       : IN  STD_LOGIC;                     -- 1-bit 輸入 A
        B       : IN  STD_LOGIC;                     -- 1-bit 輸入 B
        Opcode  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit 操作碼

        -- Outputs to 7-Segment Displays
        HEX0    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- 顯示最終的 result 位元
        -- HEX1    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- 可選: 顯示 carryout
    );
END ENTITY lab;

ARCHITECTURE Behavioral OF lab IS

    -- 內部信號
    SIGNAL alu_result_record : type_OneBitAluResult;       -- 存放函數結果的紀錄
    SIGNAL result_bit_alu    : STD_LOGIC;                -- ALU 函數計算出的原始 result (.res)
    SIGNAL final_result_bit  : STD_LOGIC;                -- 最終要顯示的 result 位元
    SIGNAL carryout_bit      : STD_LOGIC;                -- (可選) ALU 函數的 carryout (.cout)
    SIGNAL internal_carryin  : STD_LOGIC;                -- 內部決定的 CarryIn
    SIGNAL is_A_less_than_B  : STD_LOGIC;                -- 直接判斷 A < B 的結果 (1-bit signed)
    SIGNAL hex0_input        : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN

    -- 根據 Opcode 決定內部 CarryIn (用於 ALU 函數內部計算 SUB/ADD 等)
    internal_carryin <= '1' WHEN (Opcode = "0110" OR Opcode = "0111") ELSE
                        '0';

    -- 呼叫 1-bit ALU 函數以獲取 *所有* 運算的基礎結果
    -- 注意：對於 SLT，我們稍後會覆蓋它的 result
    alu_result_record <= calculate_one_bit_alu(
        A       => A,
        B       => B,
        less    => '0',           -- 此 less 輸入在此架構下不直接影響最終 SLT 輸出
        carryin => internal_carryin,
        opcode  => Opcode
    );

    -- 從函數返回的紀錄中提取需要的輸出位元
    result_bit_alu <= alu_result_record.res;  -- 獲取函數計算的原始 .res
    carryout_bit   <= alu_result_record.cout; -- (可選) 獲取進位輸出
	 

    is_A_less_than_B <= '1' WHEN (A = '0' AND B = '1') ELSE
                        '0';

    -- *** 根據 Opcode 決定最終要顯示的 result 位元 ***
    WITH Opcode SELECT
      final_result_bit <= result_bit_alu       WHEN "0000", -- AND: 使用 ALU 的 .res
                          result_bit_alu       WHEN "0001", -- OR:  使用 ALU 的 .res
                          result_bit_alu       WHEN "0010", -- ADD: 使用 ALU 的 .res (sum)
                          result_bit_alu       WHEN "0110", -- SUB: 使用 ALU 的 .res (sum of A-B)
                          is_A_less_than_B   WHEN "0111", -- SLT: 直接使用上面判斷的 A < B 結果
                          result_bit_alu       WHEN "1100", -- NOR: 使用 ALU 的 .res
                          '0'                  WHEN OTHERS; -- 預設為 '0'

    -- 準備送給 7 段顯示器解碼器的輸入
    hex0_input <= "000" & final_result_bit;      -- 將最終的 result 位元顯示在 HEX0

    -- 呼叫 7 段顯示器解碼函數來驅動顯示器
    HEX0 <= bin_to_7seg_active_low(hex0_input);
    -- 如果需要觀察 carryout，可以取消註解 HEX1 相關程式碼

END ARCHITECTURE Behavioral;