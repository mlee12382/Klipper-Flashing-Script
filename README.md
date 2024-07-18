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
* You can check out my example scripts here: [CANBus](/CANBus_Flash_Example.sh) & [USB](/USB_Flash_Example.sh). There will be excerpts from them below in the instructions.  

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

* Create the script, you can theoretically put it anywhere on the Pi that you want, I put it in my config folder so that if I change it, it's automatically backed up to github with the [klipper-backup](https://github.com/Staubgeborener/klipper-backup) plugin, and I name it `flash.sh` though you can name it whatever you want also.
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
		
		* Once you have all of your devices set up similar to the examples, then you will call each of the device functions created above like so:
			```
			echo -e "\033[1;34m\nStopping Klipper service.\033[0m"
			sudo service klipper stop
			sleep 5
			rpi_flash
			sleep 5
			octopus_flash
			sleep 5
			sb2209_flash
			sleep 5
			echo -e "\033[1;34m\nStarting Klipper service.\033[0m"
			sudo service klipper start
			``` 

		* The `sleep 5`will cause the script to pause for 5 seconds between each step to help keep things running smoothly.
		
		* You will then need to save and exit and make the script executable.
			```
			sudo chmod +x ~/printer_data/config/flash.sh
			```
		* You should then be able run the script for testing.
		
		![Example of formatting](/FlashExample01.jpg)
		
	* If you have any errors in the script it may be beneficial to run each of the commands in the functions separately to make sure everything is entered correctly. You may want to omit the `> /dev/null 2>&1` section from your commands if you used them so you can see what errors if any you are getting while testing.
		* I used ChatGPT when I was building the script initially to help with troubleshooting and getting the terminal text formatting set the way I wanted it, it's a useful tool for this type of thing if you are having issues, though it's not always correct on current implementations especially for Klipper specific stuff so be wary of trusting it completely. ie the ways it thought you could toggle Moonraker power devices from the terminal were completely wrong, at least when I was setting things up.
		

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

# USB Devices
* If you are running USB then you will need to trigger entering the bootloader so that you can flash the device. 
	* If you have an open GPIO pin on the device and your Pi then you can configure Katapult to enter the bootloader on a GPIO trigger. 
	
		* You will also need to have a relay or other power device to toggle the printer power for this to work correctly. Instructions for this are [below](#power-devices).

		* Below is an image of my Katapult settings for an Octopus v1.1 F446 board using the PS_ON pin (PE11) to trigger the bootloader. It is connected to the Pi GPIO on pin 21.

		 ![Katapult Settings Example](/KatapultGPIO.jpg)

		* Normally you have to double press the reset button to enter the bootloader to flash devices. By using the GPIO pin to enter the bootloader instead you can do it all with a script, the downside is that you need to toggle power while the pin is active to get it to enter the bootloader.

			* You should be able to use any unused pin on your board and the Pi, you just need to assign them in the Katapult settings and in your script.
			* Run a wire between the selected pin on the board and the GPIO pin on the Pi.
			
			* You will need to have gpiod installed, which you may already have depending on what you are using for ADXL stuff.	`sudo apt-get install gpiod`. More information [here](https://www.klipper3d.org/RPi_microcontroller.html#optional-identify-the-correct-gpiochip).
			
			* In my example I use `gpioset gpiochip0 21=1` followed by turning on the printer relay which enters the bootloader so I can flash the board, after which I run `gpioset gpiochip0 21=0` followed by cycling the power to return it to normal operations.
				* If the bootloader has been successfully entered then when you run`ls /dev/serial/by-id/*` you should see a device name that has 'Katapult' in it instead of 'Klipper' (this also depends on the board, some device names don't change, in which case you will know if it's in bootloader mode if it successfully flashes).
		
	* You can also simulate a double press of the reset button by connecting the GPIO on your Pi to an available RST pin on your control board if available, some boards have more than one and they're usually all tied together. This method doesn't require power relays.
		* In the following example I have GPIO 26 connected to the RST pin on the SWDIO port of the board (there is also a RST pin in EXP2 if you're not using a screen). You need to have the 'sleeps' or the toggling is too fast and it doesn't recognize it as a "double press".

			```
			bootloader_mode{
				gpioset gpiochip0 26=0
				sleep 0.1
				gpioset gpiochip0 26=1
				sleep 0.2
				gpioset gpiochip0 26=0
				sleep 0.1
				gpioset gpiochip0 26=1
			}
			```

		* You would then call the 'bootloader_mode' function just prior to your flashing function. Something similar to the following.

			```
			echo -e "\033[1;34m\nStopping Klipper service.\033[0m"
			sudo service klipper stop
			rpi_flash
			bootloader_mode
			octopus_flash
			echo -e "\033[1;34m\nStarting Klipper service.\033[0m"
			sudo service klipper start
			```

# Power Devices
* For [Moonraker Power Devices](https://moonraker.readthedocs.io/en/latest/configuration/#power)

	* The example below controls 2 relays, one named 'PSU' and the other named 'Printer'. You can have more or even a single relay being controlled. Separate the names of the devices you set up in moonraker.conf using '&'. For an example with more devices see my [CANBus Example](/CANBus_Flash_Example.sh) where I have four relays being controlled. (Technically I only need the 2 in the example below for that printer also, however, I have it turn everything on so that the printer starts and is ready to go at the end of the script.)

	* You can also see in the example that I have it set to cycle the power, turning it off, waiting 5 seconds and then turning it back on. I also have it make sure that the Klipper service is stopped after the power on since one of my printers always restarts the Klipper service when the relay is powered.
		```
		power_cycle(){
			echo -e "\033[1;34m\nCycling power to PSU and boards.\033[0m"
			curl -s -X POST "http://localhost:7125/machine/device_power/off?PSU&Printer" > /dev/null 2>&1
			sleep 5
			curl -s -X POST "http://localhost:7125/machine/device_power/on?PSU&Printer" > /dev/null 2>&1
			sleep 5
			sudo service klipper stop
		}	
		```
