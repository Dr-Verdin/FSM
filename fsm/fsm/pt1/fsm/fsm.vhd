library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm is
    Port (
        SW0 : in  STD_LOGIC;  -- Reset assíncrono ativo baixo
        SW1 : in  STD_LOGIC;  -- Input w
        KEY0 : in  STD_LOGIC; -- Clock input
        LEDR : out STD_LOGIC_VECTOR(9 downto 0) -- LED output
    );
end fsm;

architecture Behavioral of fsm is
    signal state : STD_LOGIC_VECTOR(8 downto 0) := "000000001"; -- Estado inicial y0
    signal z : STD_LOGIC := '0'; -- Saída
begin
    -- Lógica de saída
    LEDR(9) <= z; -- Conecta a saída z ao LED 9
    LEDR(0) <= state(0); -- Conecta os estados aos LEDs
    LEDR(1) <= state(1);
    LEDR(2) <= state(2);
    LEDR(3) <= state(3);
    LEDR(4) <= state(4);
    LEDR(5) <= state(5);
    LEDR(6) <= state(6);
    LEDR(7) <= state(7);
    LEDR(8) <= state(8);

    -- Processo de transição de estados
    process (KEY0, SW0)
    begin
        if SW0 = '1' then
            state <= "000000001"; -- Reset para o estado y0 
            z <= '0'; 
        elsif rising_edge(KEY0) then
            case state is
                when "000000001" => -- Estado y0
                    if SW1 = '1' then
                        state <= "000000010"; -- Vai para y1
                    else
                        state <= "000100000"; -- Vai para y5
                    end if;

                when "000000010" => -- y1
                    if SW1 = '1' then
                        state <= "000000100"; -- Vai para y2
                    else
                        state <= "000100000"; -- Vai para y5
                    end if;

                when "000000100" => -- y2
                    if SW1 = '1' then
                        state <= "000001000"; -- Vai para y3
                    else
                        state <= "000100000"; -- Vai para y5
                    end if;

                when "000001000" => -- y3
                    if SW1 = '1' then
                        state <= "000010000"; -- Vai para y4 (z=1)
                        z <= '1';
                    else
                        state <= "000100000"; -- Vai para y5
                    end if;

                when "000010000" => -- y4 (z=1)
                    if SW1 = '1' then
                        state <= "000010000"; -- Fica em y4 (z=1)
                    else
                        state <= "000100000"; -- Vai para y0
                        z <= '0'; -- Reset da saída z
                    end if;

                when "000100000" => -- y5
                    if SW1 = '1' then
                        state <= "000000001"; -- Vai para y0
                    else
                        state <= "001000000"; -- Vai para y6
                    end if;

                when "001000000" => -- y6
                    if SW1 = '1' then
                        state <= "000000001"; -- Vai para y0
                    else
                        state <= "010000000"; -- Vai para y7
                    end if;

                when "010000000" => -- y7
                    if SW1 = '1' then
                        state <= "000000001"; -- Vai para y0
                    else
                        state <= "100000000"; -- Vai para y8 (z=1)
                        z <= '1';
                    end if;

                when "100000000" => -- y8 (z=1)
                    if SW1 = '0' then
                        state <= "100000000"; -- Fica em y8 (z=1)
                    else
                        state <= "000000001"; -- Vai para y0
                        z <= '0'; -- Reset da saída z
                    end if;

                when others =>
                    state <= "000000001"; -- Padrão y0
            end case;
        end if;
    end process;

end Behavioral;