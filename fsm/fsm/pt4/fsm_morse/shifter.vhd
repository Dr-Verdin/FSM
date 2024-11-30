library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity shifter is
    port (
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        enable: in STD_LOGIC;
        input: in STD_LOGIC_VECTOR (3 downto 0);
        output: out STD_LOGIC_VECTOR (3 downto 0)
    );
end entity;

architecture Behaviour of shifter is
    signal aux : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
begin
    process(clk, reset)
    begin    
        if(reset='1') then 
            aux <= input;
        elsif(rising_edge(clk)) then
            if(enable='1') then
                aux <= aux(2 downto 0) & aux(3); --Cuidado ao usar laço de repetição em VHDL. VHDL é uma linguagem de descrição de hardware e não de programação, repetição envolvem usar contadores e sequenciadores de máquina de estado. Também tome cuidado ao definir atribuições de registradores usando variáveis, se definir um registrador de 4 bits não é possível acessar um quinto, ele pode compilar mas dará um warning. Ao compilar o código sempre leia os warnings, eles são importantes. Se tiver warning significa que algo pode dar errado, no caso o que estava dando errado era acessar um bit a mais do registrador que não havia sido definido
            end if;
        end if;
    end process;
    output <= aux;
end architecture;