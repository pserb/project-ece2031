-- ExternalMemory.VHD
-- 2024.11.02
-- uses intel's altsyncram to create a memory module
-- 16 bits of address space, 16 bits of data space

LIBRARY ieee;
LIBRARY altera_mf;
LIBRARY lpm;

USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
USE altera_mf.altera_mf_components.ALL;
USE lpm.lpm_components.ALL;

ENTITY ExternalMemory IS
    PORT (
        RESETN,
        CLOCK,
        EXTMEMADDR_EN,
        EXTMEMDATA_EN,
		  EXTMEMCONFIG_EN,
		  EXTMEMERR_EN,
        IO_WRITE : IN STD_LOGIC;
        IO_DATA : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END ExternalMemory;

ARCHITECTURE a OF ExternalMemory IS
    SIGNAL address : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL data_in : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL data_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL inter_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 SIGNAL err : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 SIGNAL config : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL wren : STD_LOGIC;
	 
	 SIGNAL write_inc_en : STD_LOGIC;
	 SIGNAL read_inc_en : STD_LOGIC;
	 SIGNAL write_inc_dir : STD_LOGIC;
	 SIGNAL read_inc_dir : STD_LOGIC;
     SIGNAL byte_en : STD_LOGIC_VECTOR(1 DOWNTO 0);
	 SIGNAL inc_val : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 
	 type state_type is (
		idle,
		incrementing,
		decrementing
	 );
	 SIGNAL state : state_type;
BEGIN
    -- use altsyncram component for memory
    -- the way this works is if EXTMEMADDR_EN is high, then the memory is being addressed
    -- that means that IO_DATA stores the address
    -- if EXTMEMDATA_EN is high, then the memory is being written to
    -- that means that IO_DATA stores the data to be written
    memory_component : altsyncram
    GENERIC MAP(
        operation_mode => "SINGLE_PORT",
        width_a => 16,
        widthad_a => 16,
        numwords_a => 2 ** 16,
        outdata_reg_a => "UNREGISTERED",
        init_file => "ExternalMemory.mif",
        read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
        intended_device_family => "MAX 10"
    )
    PORT MAP(
        clock0 => CLOCK,
        address_a => address,
        data_a => data_in,
        wren_a => wren,
        q_a => inter_out
    );

    -- Use Intel LPM IP to create tristate drivers
    IO_BUS_DATA : lpm_bustri
    GENERIC MAP(
        lpm_width => 16
    )
    PORT MAP(
        data => data_out,
        enabledt => NOT IO_WRITE AND EXTMEMDATA_EN,
        tridata => IO_DATA
    );
	 
	 -- Use Intel LPM IP to create tristate drivers
    IO_BUS_CONFIG : lpm_bustri
    GENERIC MAP(
        lpm_width => 16
    )
    PORT MAP(
        data => config,
        enabledt => NOT IO_WRITE AND EXTMEMCONFIG_EN,
        tridata => IO_DATA
    );
	 
	 -- Use Intel LPM IP to create tristate drivers
    IO_BUS_ERR : lpm_bustri
    GENERIC MAP(
        lpm_width => 16
    )
    PORT MAP(
        data => err,
        enabledt => NOT IO_WRITE AND EXTMEMERR_EN,
        tridata => IO_DATA
    );
	 
	 inc_val(2 DOWNTO 0) <= config(2 DOWNTO 0);
	 inc_val(15 DOWNTO 3) <= (OTHERS => '0');
	 write_inc_en <= config(6);
	 read_inc_en <= config(5);
	 write_inc_dir <= config(4);
	 read_inc_dir <= config(3);
	 byte_en <= config(8 DOWNTO 7);

	 WITH byte_en SELECT data_out <=
		"00000000" & inter_out(7 DOWNTO 0) WHEN "01",
		"00000000" & inter_out(15 DOWNTO 8) WHEN "10",
		inter_out WHEN OTHERS;
    
    PROCESS (CLOCK, RESETN)
    BEGIN
        IF RESETN = '0' THEN
            address <= (OTHERS => '0');
            data_in <= (OTHERS => '0');
				err <= (OTHERS => '0');
				config <= (OTHERS => '0');
				state <= idle;
            wren <= '0';
        ELSIF rising_edge(CLOCK) THEN
            IF EXTMEMADDR_EN = '1' AND state = idle THEN
                address <= IO_DATA;
            END IF;

            IF EXTMEMDATA_EN = '1' AND state = idle THEN
                IF byte_en = "01" THEN
                    data_in(7 DOWNTO 0) <= IO_DATA(7 DOWNTO 0);
                ELSIF byte_en = "10" THEN
                    data_in(15 DOWNTO 8) <= IO_DATA(15 DOWNTO 8); 
                ELSE
                    data_in <= IO_DATA;                   
                END IF;

                wren <= '1';
					 
					 IF write_inc_en = '1' AND IO_WRITE = '1' THEN
						IF write_inc_dir = '1' THEN
							state <= decrementing;
						ELSE
							state <= incrementing;
						END IF;
					 END IF;
					 
					 IF read_inc_en = '1' AND IO_WRITE = '0' THEN
						IF read_inc_dir = '1' THEN
							state <= decrementing;
						ELSE
							state <= incrementing;
						END IF;
					 END IF;
            ELSE
                wren <= '0';
            END IF;
				
				IF EXTMEMCONFIG_EN = '1' AND state = idle THEN
					config <= IO_DATA;
				END IF;
				
				IF EXTMEMERR_EN = '1' AND IO_WRITE = '1' AND state = idle THEN
					err <= (OTHERS => '0');
				END IF;
				
				IF state = incrementing THEN
					state <= idle;
					CASE byte_en IS
						WHEN "01" =>
							IF inc_val(0) = '1' THEN
								byte_en <= "10";
							END IF;
							address <= address + inc_val_shifted;
							IF inc_val_shifted > (X"FFFF" - address) THEN
								err <= X"0001";
							END IF;
						WHEN "10" =>
							IF inc_val(0) = '1' THEN
								byte_en <= "01"
								address <= address + inc_val_shifted + 1;
								IF inc_val_shifted + 1 > (X"FFFF" - address) THEN
									err <= X"0001";
								END IF;
							ELSE
								address <= address + inc_val_shifted;
								IF inc_val_shifted > (X"FFFF" - address) THEN
									err <= X"0001";
								END IF;
							END IF;
						WHEN OTHERS =>
							address <= address + inc_val;
							IF inc_val > (X"FFFF" - address) THEN
								err <= X"0001";
							END IF;
					END CASE;
				END IF;
				
				IF state = decrementing THEN
					state <= idle;
					CASE byte_en IS
						WHEN "01" =>
							IF inc_val(0) = '1' THEN
								byte_en <= "10";
								address <= address - inc_val_shifted - 1;
								IF inc_val_shifted + 1 > address THEN
									err <= X"FFFF";
								END IF
					address <= address - inc_val;
					IF inc_val > address THEN
						err <= X"FFFF";
					END IF;
				END IF;

                

        END IF;
    END PROCESS;

END a;