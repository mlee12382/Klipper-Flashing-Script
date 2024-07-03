# Disclaimer!
## **This guide is NOT meant for beginners. Ideally you will need a basic understanding of Klipper and Linux commands to implement this setup.**
## I will provide as much information here as I can to get you going but I am not going to hold your hand through setting it up.

# Introduction

* These instructions are meant to help you create a script that will flash Klipper updates to your devices by running a single command.

* These instructions will only work if your devices supports flashing a Katapult Bootloader.

* Please refer to the [Esoterical CANBus Guide](https://canbus.esoterical.online/) for specifics on setting up Katapult and for device specific settings.

* This will work with both CANBus and USB devices.

* You will need to do extensive modifications and some preliminary setup to make this work for your specific hardware. The examples provided are my personal scripts and are only meant as references.

# Getting Started
*	SSH into your Klipper host.
	
	* Set up each of your devices that will need to be flashed with a config file to easily call them up with the script:
		* Here is an example for the Raspberry Pi: 
			```
			cd klipper
			make menuconfig KCONFIG_CONFIG=config.rpi
			 ```
	* For each device you will change the name after "KCONFIG_CONFIG=" to correspond to the device being set up, you can name them whatever you want. Set your device settings up as you did when you flashed Klipper to them initially or refer to the Esoterical guide or your device documentation.

	* You can then interact with the saved configs by adding the KCONFIG_CONFIG=config.rpi to your make commands like this:

		``` 
		make clean KCONFIG_CONFIG=config.rpi
		make flash KCONFIG_CONFIG=config.rpi -j4
		```

		* The -j4 tag uses all 4 of the processing cores on the Raspberry Pi so it can theoretically finish faster.

* Create the script, you can theoretically put it anywhere on the Pi that you want, I put it in my config folder so that if I change it, it's automatically backed up to github with the [klipper-backup](https://github.com/Staubgeborener/klipper-backup) plugin, and I name it flash.sh though you can name it whatever you want also.
	```
	cd ~
	sudo nano ~/printer_data/config/flash.sh
	```
	* Start the basics of the script and set up a section for each device so that it's well organized and easy to add / remove / modify devices in the future. 
		* Also add any feedback formatting that you want, in my example I have it output status messages in blue and bold text. (The echo lines in the example) 
		* I also have any of the make commands set to not output to the terminal window to keep it visually cleaner when I run the script (> /dev/null 2>&1).
		* For any of the devices that a klipper.bin file is created I do a move and rename of the .bin file to 'device'_klipper.bin so that, in the event it doesn't flash correctly, you can flash it manually when the script completes without needing to rebuild the firmware for that device. This keeps a current klipper.bin file for each device that will be overwritten the next time the script is run.
			
			```
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
				python3 ~/Katapult/scripts/flashtool.py -i can0 -u 39c374a93450 -r
				sleep 5
				python3 ~/Katapult/scripts/flash_can.py -f ~/klipper/octopus_klipper.bin -d /dev/serial/by-id/usb-Katapult_stm32h723xx_2A003F001951313236343430-if00
			}
			
			sb2209_flash(){
				echo -e "\033[1;34m\nStep 4: Cleaning and building Klipper firmware for SB2209.\033[0m"
				make clean KCONFIG_CONFIG=config.sb2209
				make -s KCONFIG_CONFIG=config.sb2209 -j4  > /dev/null 2>&1
				mv ~/klipper/out/klipper.bin sb2209_klipper.bin
				echo -e "\033[1;34m\nStep 5: Flashing Klipper to SB2209.\033[0m"
				python3 ~/Katapult/scripts/flash_can.py -f ~/klipper/sb2209_klipper.bin -u 2730ee34bdd2
			}
			```
		* Here you can see examples for my Raspberry Pi, Octopus Max EZ running USB to CAN Bridge, and SB2209 toolhead board. 
		* 


# CANBus Devices
* This is the easiest setup for the script.

* USB to CAN Bridge devices require you to release the UUID and enter the bootloader
	* In my case, as seen in the example script it is the following line:
		* ```python3 ~/Katapult/scripts/flashtool.py -i can0 -u 39c374a93450 -r```
	*	The board should now show a /dev/serial/by-id/ path that you can use to flash the updated version of klipper to like so:
		*	```python3 ~/Katapult/scripts/flash_can.py -f ~/klipper/octopus_klipper.bin -d /dev/serial/by-id/usb-Katapult_stm32h723xx_2A003F001951313236343430-if00```

* Other CANBus devices can be flashed as described in the Esoterical guide.
	* In my case I have a BTT SB2209 and an ERCF CANBus board, here is the SB2209 flash command from my script.
		* ```python3 ~/Katapult/scripts/flash_can.py -f ~/klipper/sb2209_klipper.bin -u 2730ee34bdd2```
