LIBRARY ieee;
USE ieee.std_logic_1164.all;

--=============================================================================
-- Package Declaration: 定義 7 段顯示器解碼函數的介面
--=============================================================================
PACKAGE SevenSegment_Pkg IS

    -- 為 7 段顯示器的輸出定義一個子型別 (Subtype)
    SUBTYPE type_7SegmentVector IS STD_LOGIC_VECTOR(6 DOWNTO 0);

    -- 將 4 位元二進制轉換為低態觸發 (Active Low) 的 7 段顯示器模式的函數
    FUNCTION bin_to_7seg_active_low (
        bin_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0) -- 4 位元二進制輸入
    ) RETURN type_7SegmentVector;                 -- 返回 7 位元的顯示模式

END PACKAGE SevenSegment_Pkg;

--=============================================================================
-- Package Body: 7 段顯示器解碼函數的具體實作
--=============================================================================
PACKAGE BODY SevenSegment_Pkg IS

    FUNCTION bin_to_7seg_active_low (
        bin_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
    ) RETURN type_7SegmentVector IS
        VARIABLE seg_out_var : type_7SegmentVector; -- 使用內部變數
    BEGIN
        -- 使用 CASE 語句進行轉換
        CASE bin_in IS
            --          abcdefg (低態觸發, '0' = ON)
            WHEN "0000" => seg_out_var := "1000000"; -- 0
            WHEN "0001" => seg_out_var := "1111001"; -- 1
            WHEN "0010" => seg_out_var := "0100100"; -- 2
            WHEN "0011" => seg_out_var := "0110000"; -- 3
            WHEN "0100" => seg_out_var := "0011001"; -- 4
            WHEN "0101" => seg_out_var := "0010010"; -- 5
            WHEN "0110" => seg_out_var := "0000010"; -- 6
            WHEN "0111" => seg_out_var := "1111000"; -- 7
            WHEN "1000" => seg_out_var := "0000000"; -- 8
            WHEN "1001" => seg_out_var := "0010000"; -- 9
            WHEN "1010" => seg_out_var := "0001000"; -- A
            WHEN "1011" => seg_out_var := "0000011"; -- b
            WHEN "1100" => seg_out_var := "1000110"; -- C
            WHEN "1101" => seg_out_var := "0100001"; -- d
            WHEN "1110" => seg_out_var := "0000110"; -- E
            WHEN "1111" => seg_out_var := "0001110"; -- F
            WHEN OTHERS => seg_out_var := "1111111"; -- 其他情況 (全滅)
        END CASE;
        RETURN seg_out_var; -- 返回計算結果
    END FUNCTION bin_to_7seg_active_low;

END PACKAGE BODY SevenSegment_Pkg;