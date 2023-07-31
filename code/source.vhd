library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity project_reti_logiche is
port (
    i_clk :         in std_logic;
    i_rst :         in std_logic;
    i_start :       in std_logic;
    i_w :           in std_logic;
    o_z0 :          out std_logic_vector(7 downto 0);
    o_z1 :          out std_logic_vector(7 downto 0);
    o_z2 :          out std_logic_vector(7 downto 0);
    o_z3 :          out std_logic_vector(7 downto 0);
    o_done :        out std_logic;
    o_mem_addr :    out std_logic_vector(15 downto 0);
    i_mem_data :    in std_logic_vector(7 downto 0);
    o_mem_we :      out std_logic;
    o_mem_en :      out std_logic
);
end project_reti_logiche;

architecture project_reti_logiche_arch of project_reti_logiche is
    type State is (HEADER0, HEADER1, ADDR, ASKMEM, SAVEDATA, OUTDATA);
    signal reg0 : STD_LOGIC_VECTOR (7 downto 0) := (others=>'0');
    signal reg1 : STD_LOGIC_VECTOR (7 downto 0) := (others=>'0');
    signal reg2 : STD_LOGIC_VECTOR (7 downto 0) := (others=>'0');
    signal reg3 : STD_LOGIC_VECTOR (7 downto 0) := (others=>'0');
    signal old_reg0 : STD_LOGIC_VECTOR (7 downto 0) := (others=>'0');
    signal old_reg1 : STD_LOGIC_VECTOR (7 downto 0) := (others=>'0');
    signal old_reg2 : STD_LOGIC_VECTOR (7 downto 0) := (others=>'0');
    signal old_reg3 : STD_LOGIC_VECTOR (7 downto 0) := (others=>'0');
    signal headReg : STD_LOGIC_VECTOR (1 downto 0) := "00";
    signal addrReg : STD_LOGIC_VECTOR (15 downto 0) := (others=>'0');    
    signal currState : State := HEADER0;
    signal secondHeaderBit : std_logic := '0';
    
begin
    headerMaker : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            headReg <= (others=>'0');
            secondHeaderBit <= '0';
        else
            if currState = HEADER0 or currState = HEADER1 then
               if i_start = '1' and rising_edge(i_clk) then
                   if secondHeaderBit = '0' then
                        headReg <= headReg(0) & i_w;
                        secondHeaderBit <= '1';
                   else
                        headReg <= headReg(0) & i_w;
                    end if;
                end if;
            end if;
            if currState = OUTDATA then
                headReg <= (others=>'0');
                secondHeaderBit <= '0';
            end if;
       end if;
    end process;
    
    addressMaker : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            addrReg <= (others=>'0');
        elsif currState = ADDR then
            if i_start = '1' then
                if rising_edge(i_clk) then
                    addrReg <= addrReg(14 downto 0) & i_w;
                end if;
            end if;
        end if;
        if currState = OUTDATA then
            addrReg <= (others=>'0');
        end if;
    end process;
    
    loadingData : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            reg0 <= (others=>'0');
            reg1 <= (others=>'0');
            reg2 <= (others=>'0');
            reg3 <= (others=>'0');
        elsif currState = SAVEDATA then
            case headReg is
                when "00" =>
                    reg0 <= i_mem_data;
                    reg1 <= old_reg1;
                    reg2 <= old_reg2;
                    reg3 <= old_reg3;
                when "01" =>
                    reg0 <= old_reg0;
                    reg1 <= i_mem_data;
                    reg2 <= old_reg2;
                    reg3 <= old_reg3;
                when "10" =>
                    reg0 <= old_reg0;
                    reg1 <= old_reg1;
                    reg2 <= i_mem_data;
                    reg3 <= old_reg3;
                when "11" =>
                    reg0 <= old_reg0;
                    reg1 <= old_reg1;
                    reg2 <= old_reg2;
                    reg3 <= i_mem_data;
                when others =>
                    reg0 <= old_reg0;
                    reg1 <= old_reg1;
                    reg2 <= old_reg2;
                    reg3 <= old_reg3;
            end case;
        else
            reg0 <= old_reg0;
            reg1 <= old_reg1;
            reg2 <= old_reg2;
            reg3 <= old_reg3;
        end if;
    end process;
    
    keepDATA : process (i_rst, i_clk)
    begin
        if i_rst = '1' then
            old_reg0 <= (others=>'0');
            old_reg1 <= (others=>'0');
            old_reg2 <= (others=>'0');
            old_reg3 <= (others=>'0');
        elsif rising_edge(i_clk) then
            old_reg0 <= reg0;
            old_reg1 <= reg1;
            old_reg2 <= reg2;
            old_reg3 <= reg3;
        end if;
    end process;
    
    settingFSM : process(currState)
    begin
            o_z0 <= (others=>'0');
            o_z1 <= (others=>'0');
            o_z2 <= (others=>'0');
            o_z3 <= (others=>'0');
            o_done <= '0';
            o_mem_addr <= (others=>'0');
            o_mem_we <= '0';
            o_mem_en <= '0';
            case currState is
                when HEADER0 =>
                when HEADER1 =>
                when ADDR =>
                    if i_start = '0' then
                        o_mem_addr <= addrReg;
                    end if;
                when ASKMEM =>
                    o_mem_en <= '1';
                    o_mem_addr <= addrReg;
                when SAVEDATA =>
                    o_mem_addr <= addrReg;
                when OUTDATA =>
                    o_done <= '1';
                    o_z0 <= reg0;
                    o_z1 <= reg1;
                    o_z2 <= reg2;
                    o_z3 <= reg3;
            end case;
    end process;

    transitionFSM : process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            currState <= HEADER0;
        elsif rising_edge(i_Clk) then
                currState <= HEADER0;
                case currState is
                    when HEADER0 =>
                        currState <= HEADER0;
                        if i_start = '1' then
                            currState <= HEADER1;
                        end if;
                    when HEADER1 =>
                        currState <= ADDR;
                    when ADDR =>
                        currState <= ADDR;
                         if i_start = '0' then
                            currState <= ASKMEM;
                         end if;
                    when ASKMEM =>
                            currState <= SAVEDATA;
                    when SAVEDATA =>
                            currState <= OUTDATA;
                    when OUTDATA =>
                            currState <= HEADER0;
                end case;
        end if;
    end process;
end project_reti_logiche_arch;
