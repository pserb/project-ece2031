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
        IO_WRITE : IN STD_LOGIC;
        IO_DATA : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END ExternalMemory;

ARCHITECTURE a OF ExternalMemory IS
    SIGNAL address : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL data_in : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL data_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL wren : STD_LOGIC;
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

    -- Use Intel LPM IP to create tristate drivers
    IO_BUS : lpm_bustri
    GENERIC MAP(
        lpm_width => 16
    )
    PORT MAP(
        data => data_out,
        enabledt => NOT IO_WRITE,
        tridata => IO_DATA
    );

    PROCESS (CLOCK, RESETN)
    BEGIN
        IF RESETN = '0' THEN
            address <= (OTHERS => '0');
            data_in <= (OTHERS => '0');
            wren <= '0';
        ELSIF rising_edge(CLOCK) THEN
            IF EXTMEMADDR_EN = '1' THEN
                address <= IO_DATA;
            END IF;

            IF EXTMEMDATA_EN = '1' THEN
                data_in <= IO_DATA;
                wren <= '1';
            ELSE
                wren <= '0';
            END IF;
        END IF;
    END PROCESS;

END a;