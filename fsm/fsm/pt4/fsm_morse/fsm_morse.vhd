library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity fsm_morse is
    port(
        clk: in STD_LOGIC;
        reset: in STD_LOGIC;
        input_letter: in STD_LOGIC_VECTOR(2 downto 0); -- vetor para ser lido nos switches
        signal_out: out STD_LOGIC  -- LED que será acesso
    );
end entity;

architecture Behaviour of fsm_morse is
	signal start : STD_LOGIC; --sinal para indicar que o sistema pode emitir o código morse(ativar em 1 ao resetar o sistema, desativar em 0 quando no estado do SHIFT o número de bits for alcançado
    signal shift_output: STD_LOGIC_VECTOR(3 downto 0); --sinal para saída do shift register
    signal enable_shifter: STD_LOGIC := '0'; -- sinal que habilita o shift register.
    signal enable_counter05, enable_counter15, enable_counter_low: STD_LOGIC := '0'; -- sinal que habilita os contadores. Esses só devem estar ativos no estado dos contadores(ativar um por estado de contador), nos demais estados esses devem estar desativados.
    signal reset_counter05, reset_counter15, reset_counter_low: STD_LOGIC := '0'; -- sinal que reseta os contadores. Esses só devem estar desativados no estado dos contadores(desativar um por estado de contador), nos demais estados eles devem estar desligados
    signal rollover_counter05, rollover_counter15, rollover_counter_low: STD_LOGIC := '0'; -- sinal de rollover indicando que o contador terminou sua contagem
    signal current_bit: STD_LOGIC := '0'; -- sinal corresponde ao bit atual sendo lido pela saída do shift register
    signal input_vector: STD_LOGIC_VECTOR(3 downto 0); -- mapeamento dos bits pelas switches
    signal character_size: integer range 0 to 4 := 0;  --tamanho do vetor de caracteres da letra

begin
	-- lendo a entrada(input_letter) e armazenando em um registrador(input_vector) os bits correspondentes as letras
    process(input_letter)
    begin
        case input_letter is
            when "000" => 
					input_vector <= "0100"; -- A ".-", coloquei o ponto como 0 e traço como 1, completei com zero os caracteres que não importam para ter tamanho fixo de 4
					character_size <= 2; -- Como a letra A só tem dois caracteres, . e - então esse registrador armazena 2(é um sinal representando um número inteiro)
            when "001" =>
					input_vector <= "1000"; -- B "_..."
					character_size <= 4;
            when "010" =>
					input_vector <= "1010"; -- C "_._."
					character_size <= 4;
            when "011" =>
					input_vector <= "1000"; -- D "_.."
					character_size <= 3;
            when "100" => 
					input_vector <= "0000"; -- E "."
					character_size <= 1;
            when "101" => 
					input_vector <= "0010"; -- F ".._."
					character_size <= 4;
            when "110" => 
					input_vector <= "1100"; -- G "_ _."
					character_size <= 3;
            when "111" => 	
					input_vector <= "0000"; -- H "...."
					character_size <= 4;
            when others => -- condição adversa, mesmo que todas tenham sido atendidas definir para demais casos(other) garante que a implementação seja como desejada
					input_vector <= "0000"; -- Don't care
					character_size <= 0;
        end case;
    end process;

	--Nessa parte estou criando instâncias para o shift register, counter05, counter15 e conterlow
    shift: entity work.shifter
        port map (
            clk => clk,
            reset => reset,
            enable => enable_shifter,
            input => input_vector,
            output => shift_output
        );

	--CONTADOR de 0.5 segundos
    counter05: entity work.contador
        generic map (
            n => 4,
            k => "0001",  
            c => 25000000
				--c => 1
        )
        port map (
            clk => clk,
            reset => reset_counter05, 
            enable => enable_counter05,
            output => open,
            rollover => rollover_counter05
        );

	--contador de 1.5 segundos
    counter15: entity work.contador
        generic map (
            n => 4,
            k => "0001", 
            c => 75000000
				-- c => 3
        )
        port map (
            clk => clk,
            reset => reset_counter15, 
            enable => enable_counter15,
            output => open,
            rollover => rollover_counter15
        );

	-- contador de 1.0 segundos
    counter_low: entity work.contador
        generic map (
            n => 4,
            k => "0001",  
            c => 10000000
				--c => 2
			)
        port map (
            clk => clk,
            reset => reset_counter_low, 
            enable => enable_counter_low,
            output => open,
            rollover => rollover_counter_low
        );

    process(clk, reset)
        type state_type is (IDLE, COUNT_05, COUNT_15, COUNT_LOW, SHIFT); --definição dos estados, instrução de alto nível para abstração, basicamente colocando nome nos estados ao invés de simplesmente chamar de 00, 01, 10, 11...
        variable state: state_type := IDLE; --criando a variável estado e atribuíndo valor inicial para IDLE
        variable bit_counter: integer range 0 to 4 := 0;--criando a vari´ável para contar os bits que o shift register leu
    begin
		--reset assincrono. Nesse estado a variável start é setado para 1, estado para IDLE, apagar LED, resetar contadores, resetar contador de bits e desabilitar contadores
        if reset = '0' then
				start <= '1';
            state := IDLE;
            signal_out <= '0';
            enable_counter05 <= '0';
            enable_counter15 <= '0';
            enable_counter_low <= '0';
            enable_shifter <= '0';
            bit_counter := 0; -- resetando a contagem dos bits
            reset_counter05 <= '1'; 
            reset_counter15 <= '1';
            reset_counter_low <= '1';
				
		-- durante as transições de clock os estados podem ser transicionados
        elsif rising_edge(clk) then
            case state is
                when IDLE => -- estrado inicial do circuito, ele espera o reswe sair de 1 para 0, quando o reset é acionado o proximo estado é o SHIFT
						-- contadores desabilitados e resetados
						enable_shifter <= '0'; -- sinal que habilita o shift register.
						enable_counter05 <= '0';
						enable_counter15 <= '0';
						enable_counter_low <= '0';
						
						--caso o sinal start estiver em 1 mudará para o estado SHIFT; caso o sinal start estiver em 0 se manter no estado idle(state := IDLE;)
						if start = '1' then
							enable_shifter <= '1';
							current_bit <= shift_output(3); -- le o bit mais significativo
							state := SHIFT; -- muda o estado do shift
						end if;
							
                when COUNT_05 =>
						signal_out <= '1'; -- ligar LED
						enable_counter05 <= '1'; -- habilitar contador 0,5
						reset_counter05 <= '0'; -- defsabilitar reset co contador
						enable_shifter <= '0'; -- desabilitar shift
						
						--quando o contador terminar de contar(rollover_counter05), desabiltiar o contador e mudar estado para COUNT_LOW
						if rollover_counter05 = '1' then
							enable_counter05 <= '0';
							state := COUNT_LOW;
						end if;

                when COUNT_15 =>
                  signal_out <= '1'; -- ligar LED
						enable_counter15 <= '1'; -- habilitar contador 1,5
						reset_counter15 <= '0'; -- defsabilitar reset co contador
						enable_shifter <= '0'; -- desabilitar shift
						
						--quando o contador terminar de contar(rollover_counter15), desabiltiar o contador e mudar estado para COUNT_LOW
						if rollover_counter15 = '1' then
							enable_counter15 <= '0';
							state := COUNT_LOW;
						end if;

                when COUNT_LOW =>  -- led apagado por um curto periodo, o proximo estado será SHIFT
						signal_out <= '0'; -- desligar LED
						enable_counter_low <= '1'; -- habilitar contador low
						reset_counter_low <= '0'; -- defsabilitar reset do contador
						enable_shifter <= '0'; -- desabilitar shift
						
						--quando o contador terminar de contar(rollover_counter_low), desabiltiar o contador e mudar estado para SHIFT
						if rollover_counter_low = '1' then
							enable_counter_low <= '0';
							current_bit <= shift_output(3); -- le o bit
							state := SHIFT;
						end if;

                when SHIFT => -- 
						reset_counter05 <= '1';
						reset_counter15 <= '1';
						reset_counter_low <= '1';
						enable_shifter <= '0'; -- sinal que habilita o shift register.
					
						if bit_counter = character_size then
							signal_out <= '0'; -- desliga o led
							bit_counter := 0;
							start <= '0';
							state:= IDLE; -- VOLTA PARA O idle
						else
							if current_bit <= '0' then
								state := COUNT_05; -- ponto
								bit_counter := bit_counter + 1;
							else
								state := COUNT_15; -- traço
								bit_counter := bit_counter + 1;
							end if;
						end if;
            end case;
        end if;
    end process;
end architecture Behaviour;