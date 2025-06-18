LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY simple_cpu_top IS
    PORT (
        -- Inputs from switches
        SW    : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        -- Clock from pushbutton
        KEY   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        -- Outputs to 7-segment displays
        HEX0  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX3  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX4  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX5  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END simple_cpu_top;

ARCHITECTURE structural OF simple_cpu_top IS
    -- Component Declarations
    COMPONENT seven_seg_hex_decoder IS
        PORT (
            hex_in        : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            seven_seg_out : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT alu IS
        PORT (
            operand_a : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            operand_b : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            alu_op    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            result    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    -- Signals for internal connections
    SIGNAL clk           : STD_LOGIC;
    SIGNAL data_in       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL opcode        : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL rs_addr       : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL rt_addr       : STD_LOGIC_VECTOR(1 DOWNTO 0);

    -- Register file and bus
    TYPE reg_array IS ARRAY (0 TO 3) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL registers     : reg_array := (OTHERS => (OTHERS => '0'));
    SIGNAL bus           : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- ALU signals
    SIGNAL alu_a, alu_b   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL alu_result    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL alu_op_signal : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- Control Unit FSM signals
    TYPE state_type IS (s_idle, s_decode, s_load, s_move, s_exec, s_writeback);
    SIGNAL current_state, next_state : state_type;
    
    -- Display signals
    SIGNAL rs_val, rt_val : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN
    -- Map inputs from switches and key
    -- KEY[0] is active-low, so invert it for a rising-edge clock
    clk       <= NOT KEY(0);
    data_in   <= SW(7 DOWNTO 0);
    opcode    <= SW(11 DOWNTO 8);
    rs_addr   <= SW(13 DOWNTO 12);
    rt_addr   <= SW(15 DOWNTO 14);

    -- Instantiate ALU
    main_alu : alu
        PORT MAP(
            operand_a => alu_a,
            operand_b => alu_b,
            alu_op    => alu_op_signal,
            result    => alu_result
        );

    -- Control Unit (FSM)
    fsm_seq_proc : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            current_state <= next_state;
        END IF;
    END PROCESS;

    fsm_comb_proc : PROCESS (current_state, opcode, rs_addr, rt_addr, registers, data_in, alu_result)
        -- Control signals with default values
        VARIABLE reg_write_en : STD_LOGIC := '0';
        VARIABLE dest_reg     : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
        VARIABLE bus_content  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    BEGIN
        -- Default assignments for each cycle
        reg_write_en := '0';
        alu_op_signal <= "111"; -- NOP
        next_state <= s_idle;
        
        CASE current_state IS
            WHEN s_idle =>
                next_state <= s_decode;
                
            WHEN s_decode =>
                CASE opcode IS
                    WHEN "0000" => -- LOAD
                        next_state <= s_load;
                    WHEN "0001" => -- MOVE
                        next_state <= s_move;
                    WHEN "0010" | "0011" | "0100" | "0101" | "1001" => -- ALU Ops
                        next_state <= s_exec;
                    WHEN OTHERS =>
                        next_state <= s_idle;
                END CASE;
                
            WHEN s_load =>
                bus_content := data_in;
                dest_reg := rs_addr;
                reg_write_en := '1';
                next_state <= s_idle;
                
            WHEN s_move =>
                bus_content := registers(to_integer(unsigned(rt_addr)));
                dest_reg := rs_addr;
                reg_write_en := '1';
                next_state <= s_idle;

            WHEN s_exec =>
                alu_a <= registers(to_integer(unsigned(rs_addr)));
                alu_b <= registers(to_integer(unsigned(rt_addr)));
                CASE opcode IS
                    WHEN "0010" => alu_op_signal <= "000"; -- ADD
                    WHEN "0011" => alu_op_signal <= "001"; -- AND
                    WHEN "0101" => alu_op_signal <= "010"; -- SUB(A-B)
                    WHEN "0100" => alu_op_signal <= "011"; -- SLT
                    WHEN "1001" => alu_op_signal <= "100"; -- SUB(B-A)
                    WHEN OTHERS => alu_op_signal <= "111"; -- NOP
                END CASE;
                next_state <= s_writeback;

            WHEN s_writeback =>
                bus_content := alu_result;
                dest_reg := rs_addr;
                reg_write_en := '1';
                next_state <= s_idle;

        END CASE;

        -- Register File Write Logic
        reg_write_proc: PROCESS (clk)
        BEGIN
            IF rising_edge(clk) THEN
                IF reg_write_en = '1' THEN
                    registers(to_integer(unsigned(dest_reg))) <= bus_content;
                END IF;
            END IF;
        END PROCESS;
    END PROCESS;

    -- Continuous Display Logic
    -- BUS display shows the current value of the data switches
    bus_val_display: bus <= data_in;

    -- Rs and Rt displays show the current value of the selected registers
    rs_val <= registers(to_integer(unsigned(rs_addr)));
    rt_val <= registers(to_integer(unsigned(rt_addr)));

    -- Instantiate 7-Segment Decoders for all displays
    -- Display BUS value on HEX1 and HEX0
    HEX0_DECODER : seven_seg_hex_decoder PORT MAP(hex_in => bus_val_display(3 DOWNTO 0),  seven_seg_out => HEX0);
    HEX1_DECODER : seven_seg_hex_decoder PORT MAP(hex_in => bus_val_display(7 DOWNTO 4),  seven_seg_out => HEX1);

    -- Display Rs value on HEX3 and HEX2
    HEX2_DECODER : seven_seg_hex_decoder PORT MAP(hex_in => rs_val(3 DOWNTO 0),  seven_seg_out => HEX2);
    HEX3_DECODER : seven_seg_hex_decoder PORT MAP(hex_in => rs_val(7 DOWNTO 4),  seven_seg_out => HEX3);
    
    -- Display Rt value on HEX5 and HEX4
    HEX4_DECODER : seven_seg_hex_decoder PORT MAP(hex_in => rt_val(3 DOWNTO 0),  seven_seg_out => HEX4);
    HEX5_DECODER : seven_seg_hex_decoder PORT MAP(hex_in => rt_val(7 DOWNTO 4),  seven_seg_out => HEX5);

END structural;