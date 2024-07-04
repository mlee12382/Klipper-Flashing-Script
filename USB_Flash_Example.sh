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
	python3 ~/Katapult/scripts/flash_can.py -f ~/klipper/octopus_klipper.bin -d /dev/serial/by-id/usb-katapult_stm32f446xx_21003C000C51303432383339-if00
}

power_cycle(){
	echo -e "\033[1;34m\nCycling power to PSU and boards.\033[0m"
	curl -s -X POST "http://localhost:7125/machine/device_power/off?PSU&Printer" > /dev/null 2>&1
	sleep 5
	curl -s -X POST "http://localhost:7125/machine/device_power/on?PSU&Printer" > /dev/null 2>&1
	sleep 5
	sudo service klipper stop

}

echo -e "\033[1;34m\nStopping Klipper service.\033[0m"
sudo service klipper stop

power_cycle

rpi_flash

gpioset gpiochip0 21=1

power_cycle

octopus_flash

gpioset gpiochip0 21=0

power_cycle

echo -e "\033[1;34m\nStarting Klipper service.\033[0m"
sudo service klipper start
