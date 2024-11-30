library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity contador is
    generic(n: natural:=4; k: STD_LOGIC_VECTOR:="1111"; c: natural:=50000000);
    port (
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        enable: in STD_LOGIC;
        output: out STD_LOGIC_VECTOR (n-1 downto 0);
        rollover: out STD_LOGIC :='0'
    );
end entity;

architecture Behaviour of contador is

    signal rapido: natural:=0;
    signal lento: STD_LOGIC_VECTOR (n-1 downto 0);

begin

    process (clk, reset)
    begin
        if(reset='1') then
            lento <= (others => '0');
			rollover <= '0'; --Colocar o rollover para zero ao resetar
        elsif(rising_edge(clk)) then
            if(enable='1') then
                rapido <= rapido+1;
                if(rapido=c-1) then
                    if(lento=k) then
                        lento <= (others => '0');
                        rapido <= 0;
                        rollover <= '1';
                    else
                        lento <= lento+1;
                        rapido <= 0; 
                        rollover <= '0';
                    end if;
                end if;
            else
                rapido <= rapido;
            end if;
        end if;
    end process;
    output <= lento;

end architecture Behaviour;