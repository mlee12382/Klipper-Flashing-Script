#!/bin/bash

cd "$HOME/klipper"

rpi_flash(){
	echo -e "\033[1;34m\nStep 1: Cleaning and flashing Klipper to Raspberry Pi.\033[0m"
	make clean KCONFIG_CONFIG=config.rpi
	make flash KCONFIG_CONFIG=config.rpi -j4 > /dev/null 2>&1
}

octopus_flash(){
	echo -e "\033[1;34m\nStep 2: Cleaning and building Klipper firmware for Octopus.\033[0m"
	make clean KCONFIG_CONFIG=config.octopus
	make -s KCONFIG_CONFIG=config.octopus -j4  > /dev/null 2>&1
	mv ~/klipper/out/klipper.bin octopus_klipper.bin
	echo -e "\033[1;34m\nStep 3: Flashing Klipper to Octopus.\033[0m"
	python3 ~/katapult/scripts/flashtool.py -i can0 -u 39c374a93450 -r
	sleep 5
	python3 ~/katapult/scripts/flash_can.py -f ~/klipper/octopus_klipper.bin -d /dev/serial/by-id/usb-Katapult_stm32h723xx_2A003F001951313236343430-if00
}

sb2209_flash(){
	echo -e "\033[1;34m\nStep 4: Cleaning and building Klipper firmware for SB2209.\033[0m"
	make clean KCONFIG_CONFIG=config.sb2209
	make -s KCONFIG_CONFIG=config.sb2209 -j4  > /dev/null 2>&1
	mv ~/klipper/out/klipper.bin sb2209_klipper.bin
	echo -e "\033[1;34m\nStep 5: Flashing Klipper to SB2209.\033[0m"
	python3 ~/katapult/scripts/flash_can.py -f ~/klipper/sb2209_klipper.bin -u 2730ee34bdd2
}

ercf_flash(){
	echo -e "\033[1;34m\nStep 6: Cleaning and building Klipper firmware for ERCF.\033[0m"
	make clean KCONFIG_CONFIG=config.ercfv1.1
	make -s KCONFIG_CONFIG=config.ercfv1.1 -j4  > /dev/null 2>&1
	mv ~/klipper/out/klipper.bin ercf_klipper.bin
	echo -e "\033[1;34m\nStep 7: Flashing Klipper to ERCF.\033[0m"
	python3 ~/katapult/scripts/flash_can.py -f ~/klipper/ercf_klipper.bin -u f079bd60e64b
}

hotkey_flash(){
	echo -e "\033[1;34m\nStep 8: Cleaning and building Klipper firmware for Hotkeys.\033[0m"
	make clean KCONFIG_CONFIG=config.hotkey
	make -s KCONFIG_CONFIG=config.hotkey -j4 > /dev/null 2>&1
	echo -e "\033[1;34m\nStep 9: Flashing Klipper to Hotkeys.\033[0m"
	make KCONFIG_CONFIG=config.hotkey flash FLASH_DEVICE=/dev/serial/by-id/usb-Klipper_rp2040_E6625C48930D4133-if00
}

cartographer_flash(){
	echo -e "\033[1;34m\nStep 9: Flashing Klipper to Cartographer.\033[0m"
	python3 ~/katapult/scripts/flash_can.py -f ~/cartographer-klipper/firmware/v3/Cartographer_CAN_1000000_8kib_offset.bin -u 3de91f25c776
}

power_cycle(){
	echo -e "\033[1;34m\nCycling power to PSU and boards.\033[0m"
	curl -s -X POST "http://localhost:7125/machine/device_power/off?PSU&Printer&Steppers&Bed" > /dev/null 2>&1
	sleep 5
	curl -s -X POST "http://localhost:7125/machine/device_power/on?PSU&Printer&Steppers&Bed" > /dev/null 2>&1
	sleep 5

}

echo -e "\033[1;34m\nStopping Klipper service.\033[0m"
sudo service klipper stop

power_cycle

rpi_flash

power_cycle

octopus_flash

power_cycle

sb2209_flash

power_cycle

ercf_flash

power_cycle

hotkey_flash

power_cycle

cartographer_flash

power_cycle

echo -e "\033[1;34m\nStarting Klipper service.\033[0m"
sudo service klipper start

