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
		  EXTMEMID_EN,
		  EXTMEMBOUNDS_EN,
        IO_WRITE : IN STD_LOGIC;
        IO_DATA : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END ExternalMemory;

ARCHITECTURE a OF ExternalMemory IS
	 SIGNAL id : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 SIGNAL id_a : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 SIGNAL id_b : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 SIGNAL bound_in_a : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 SIGNAL bound_out_a : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 SIGNAL bound_in_b : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 SIGNAL bound_out_b : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL address : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL data_in : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL data_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 SIGNAL err : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 SIGNAL config : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL wren : STD_LOGIC;
	 SIGNAL wren_bound_a: STD_LOGIC;
	 SIGNAL wren_bound_b: STD_LOGIC;
	 
	 SIGNAL write_inc_en : STD_LOGIC;
	 SIGNAL read_inc_en : STD_LOGIC;
	 SIGNAL write_inc_dir : STD_LOGIC;
	 SIGNAL read_inc_dir : STD_LOGIC;
	 SIGNAL inc_val : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 
	 type state_type is (
		idle,
		incrementing,
		decrementing
	 );
	 SIGNAL state : state_type;
	 
	 type bounds_state_type is (
		idle,
		check
	 );
	 SIGNAL bounds_state : bounds_state_type;
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
        q_a => data_out
    );
	 
	 -- use altsyncram component for bounds
    -- the way this works is if EXTMEMADDR_EN is high, then the memory is being addressed
    -- that means that IO_DATA stores the address
    -- if EXTMEMDATA_EN is high, then the memory is being written to
    -- that means that IO_DATA stores the data to be written
    bounds_memory_component : altsyncram
    GENERIC MAP(
        operation_mode => "DUAL_PORT",
        width_a => 16,
        widthad_a => 16,
        numwords_a => 2 ** 16,
        outdata_reg_a => "UNREGISTERED",
		  width_b => 16,
        widthad_b => 16,
        numwords_b => 2 ** 16,
        outdata_reg_b => "UNREGISTERED",
        init_file => "ExternalMemoryBounds.mif",
        read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
        intended_device_family => "MAX 10"
    )
    PORT MAP(
        clock0 => CLOCK,
        address_a => id_a,
        data_a => bound_in_a,
        wren_a => wren_bound_a,
        q_a => bound_out_a,
		  address_b => id_b,
        data_b => bound_in_b,
        wren_b => wren_bound_b,
        q_b => bound_out_b
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

    PROCESS (CLOCK, RESETN)
    BEGIN
        IF RESETN = '0' THEN
            address <= (OTHERS => '0');
            data_in <= (OTHERS => '0');
				err <= (OTHERS => '0');
				config <= (OTHERS => '0');
				state <= idle;
            wren <= '0';
				
				id_a <= (OTHERS => '0');
            bound_in_a <= (OTHERS => '0');
				wren_bound_a <= '0';
				id_b <= (OTHERS => '0');
            bound_in_b <= (OTHERS => '0');
				wren_bound_b <= '0';
				bounds_state <= idle;
        ELSIF rising_edge(CLOCK) THEN
            IF EXTMEMADDR_EN = '1' AND state = idle THEN
                address <= IO_DATA;
            END IF;
				
				IF EXTMEMID_EN = '1' AND state = idle AND bounds_state = idle THEN
					id <= IO_DATA;
				END IF;
				
				IF EXTMEMBOUNDS_EN = '1' AND state = idle THEN
					IF bounds_state = idle THEN
						bounds_state <= check;
						IF id = X"0000" THEN
							id_a <= id;
						ELSE
							id_a <= id - 1;
						END IF;
						
						IF id = X"FFFF" THEN
							id_b <= id;
						ELSE
							id_b <= id + 1;
						END IF;
					ELSIF bounds_state = check
						AND (bound_out_a <  IO_DATA OR IO_DATA = bound_out_a)
						AND (bound_out_b > IO_DATA OR IO_DATA = bound_out_b) THEN
						bounds_state <= idle;
						IF id = X"0000" THEN
							id_a <= id;
						ELSE
							id_a <= id - 1;
						END IF;
						id_b <= id;
						bound_in_b <= IO_DATA;
						wren_bound_b <= '1';
					ELSE
						err <= X"0002";
						bounds_state <= idle;
					END IF;
				END IF;

            IF EXTMEMDATA_EN = '1' AND state = idle THEN
					IF (address < bound_out_b OR address = bound_out_b) AND bound_out_a < address THEN
					 data_in <= IO_DATA;
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
						err <= X"0003";
						wren <= '0';
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
					address <= address + inc_val;
					IF inc_val > (X"FFFF" - address) THEN
						err <= X"0001";
					END IF;
				END IF;
				
				IF state = decrementing THEN
					state <= idle;
					address <= address - inc_val;
					IF inc_val > address THEN
						err <= X"FFFF";
					END IF;
				END IF;
        END IF;
    END PROCESS;

END a;