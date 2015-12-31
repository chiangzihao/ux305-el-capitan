#!/bin/sh

# Bold / Non-bold
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[1;34m"
OFF="\033[m"
let gID=$(id -u)

# Repository location
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
GIT_DIR="${REPO}"

# SSDT variables
SSDT_DptfTabl=""
SSDT_SaSsdt=""

locate_ssdt()
{
	SSDT_DptfTabl=$(grep -l "DptfTabl" $1/*.dsl)	
	echo "${BLUE}[SSDT]${OFF}: Located DptfTabl SSDT in ${SSDT_DptfTabl}"
		
	SSDT_SaSsdt=$(grep -l "SaSsdt" $1/*.dsl)	
	echo "${BLUE}[SSDT]${OFF}: Located SaSsdt SSDT in ${SSDT_SaSsdt}"
}

git_update()
{
	cd ${REPO}
	echo "${GREEN}[GIT]${OFF}: Updating local data to latest version"
	
	echo "${BLUE}[GIT]${OFF}: Updating to latest git master"
	git pull
}

decompile_dsdt() 
{
	echo "${GREEN}[DSDT]${OFF}: Decompiling DSDT / SSDT in ./DSDT/raw"
	cd "${REPO}"
	
	./tools/iasl -w1 -da -dl -fe DSDT/refs.txt ./DSDT/raw/DSDT.aml ./DSDT/raw/SSDT-*.aml &> ./logs/dsdt_decompile.log
	echo "${BLUE}[DSDT]${OFF}: Log created in ./logs/dsdt_decompile.log"
	
	locate_ssdt ./DSDT/raw
	
	rm ./DSDT/decompiled/* 2&>/dev/null
	cp -v ./DSDT/raw/DSDT.dsl ./DSDT/decompiled/
	cp -v ${SSDT_DptfTabl} ./DSDT/decompiled/	
	cp -v ${SSDT_SaSsdt} ./DSDT/decompiled/	
}

patch_dsdt()
{
	echo "${GREEN}[DSDT]${OFF}: Patching DSDT / SSDT"
	
	locate_ssdt ./DSDT/decompiled

	echo "${BOLD}[rename] Rename GFX0 to IGPU${OFF}"
	perl -p -i -e "s/GFX0/IGPU/g" ./DSDT/decompiled/*.dsl

	echo "${BOLD}[rename] Rename EHC1/EHC2 to EH01/EH02${OFF}"
	perl -p -i -e "s/EHC1/EH01/g" ./DSDT/decompiled/*.dsl
	perl -p -i -e "s/EHC2/EH02/g" ./DSDT/decompiled/*.dsl		

	echo "${BOLD}[rename] Rename B0D3 to HDAU${OFF}"
	perl -p -i -e "s/B0D3/HDAU/g" ./DSDT/decompiled/*.dsl
	

	echo "${BLUE}[DSDT]${OFF}: Patching DSDT in ./DSDT/decompiled"

	echo "${BOLD}[syn] Compiler Cleanup${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/cleanup.txt ./DSDT/decompiled/DSDT.dsl

	
	echo "${BOLD}[sys] Remove _DSM Methods${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/remove_dsm.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[syn] Fix ADBG Error${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/fix_adbg.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[bat] Battery Fixes${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/battery.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] IRQ Fix${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/irq.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] SMBUS Fix${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/smbus.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] OS Check Fix${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/system_OSYS.txt ./DSDT/decompiled/DSDT.dsl
	
	echo "${BOLD}[sys] AC Adapter Fix${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/system_AC.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] Add MCHC${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/mchc.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] Add IMEI${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/imei.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] Fix Non-zero Mutex${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/mutex.txt ./DSDT/decompiled/DSDT.dsl
	
	echo "${BOLD}[sys] Add LPC${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/lpc.txt ./DSDT/decompiled/DSDT.dsl
	
	echo "${BOLD}[audio] Audio Layout 3${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/audio_HDEF-layout3.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[usb] Fix USB _PRW${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/usb.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[gfx] Broadwell Backlight, HDAU Layout 3${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/broadwell_gfx.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] HPET${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/hpet.txt ./DSDT/decompiled/DSDT.dsl	

	echo "${BOLD}[sys] PNOT${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/pnot.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] Shutdown Fix and _WAK Fix${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/shutdown_wak.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] ALS, Lid Sleep, FN Keys${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/zenbook.txt ./DSDT/decompiled/DSDT.dsl	

	echo "${BOLD}[sys] SMCD${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/smcd.txt ./DSDT/decompiled/DSDT.dsl	

	
	########################
	# SSDT-DptfTabl Patches
	########################

	echo "${BLUE}[SSDT-DptfTabl]${OFF}: Patching ${SSDT_DptfTabl}"
	perl -p -i -e "s/External \(_SB_.PCI0.PEG0.PEGP.SGPO, MethodObj\)//g" ${SSDT_DptfTabl}

	echo "${BOLD}[syn] Compiler Cleanup${OFF}"
	./tools/patchmatic ${SSDT_DptfTabl} ./DSDT/patches/cleanup.txt ${SSDT_DptfTabl}


	echo "${BOLD}_BST package size${OFF}"
	./tools/patchmatic ${SSDT_DptfTabl} ./DSDT/patches/_BST-package-size.txt ${SSDT_DptfTabl}

	########################
	# SSDT-SaSsdt Patches
	########################

	echo "${BLUE}[SSDT-SaSsdt]${OFF}: Patching ${SSDT_SaSsdt}"
	perl -p -i -e "s/External \(_SB_.PCI0, DeviceObj\)//g" ${SSDT_SaSsdt}
	perl -p -i -e "s/External \(_SB_.PCI0.PEG0, DeviceObj\)//g" ${SSDT_SaSsdt}
	perl -p -i -e "s/External \(_SB_.PCI0.PEG0.PEGP, DeviceObj\)//g" ${SSDT_SaSsdt}
	perl -p -i -e "s/External \(_SB_.PCI0.PEG0.PEGP.SGPO, MethodObj\)/External \(_SB_.PCI0, DeviceObj\) External \(_SB_.PCI0.PEG0, DeviceObj\) External \(_SB_.PCI0.PEG0.PEGP, DeviceObj\) External \(_SB_.PCI0.PEG0.PEGP.SGPO, MethodObj\)/g" ${SSDT_SaSsdt}

	echo "${BOLD}[syn] Compiler Cleanup${OFF}"
	./tools/patchmatic ${SSDT_SaSsdt} ./DSDT/patches/cleanup.txt ${SSDT_SaSsdt}
}

compile_dsdt()
{
	echo "${GREEN}[DSDT]${OFF}: Compiling DSDT / SSDT in ./DSDT/compiled"
	cd "${REPO}"
	
	locate_ssdt ./DSDT/decompiled

	rm -rf ./DSDT/compiled/*
	
	echo "${BLUE}[SSDT]${OFF}: Copying untouched original SSDTs to ./DSDT/compiled"
	grep -L "DptfTabl\|SaSsdt\|Cpu0Ist\|CpuSsdt\|CppcTabl\|Cpc_Tabl" ./DSDT/raw/SSDT-[0-9].aml ./DSDT/raw/SSDT-[1-9][0-9].aml | xargs -I{} cp -v {} ./DSDT/compiled

	echo "${BLUE}[DSDT]${OFF}: Compiling DSDT to ./DSDT/compiled"
	./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/DSDT.aml -I ./DSDT/decompiled/ ./DSDT/decompiled/DSDT.dsl | tail -1

	echo "${BLUE}[SSDT-10]${OFF}: Compiling SSDT-DptfTabl to ./DSDT/compiled"
	./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/`basename -s dsl ${SSDT_DptfTabl}`aml -I ./DSDT/decompiled/ ${SSDT_DptfTabl} | tail -1

	echo "${BLUE}[SSDT-12]${OFF}: Compiling SSDT-SaSsdt to ./DSDT/compiled"
	./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/`basename -s dsl ${SSDT_SaSsdt}`aml -I ./DSDT/decompiled/ ${SSDT_SaSsdt} | tail -1

	# Additional custom SSDT
	# ssdtPRgen (P-states / C-states)
	echo "${BLUE}[PRgen]${OFF}: Compiling ssdtPRgen to ./DSDT/compiled"
	prgen=0
	#UX305LA i5
	if [[ `sysctl machdep.cpu.brand_string` == *"i5-5200U"* ]]
	then
		echo "${BLUE}[PRgen]${OFF}: Intel ${BOLD}i5-5200U${OFF} processor found"
		./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/SSDT-pr.aml ./DSDT/custom/SSDT-pr-i5.dsl | tail -1
		prgen=1
	fi
	#UX305FA Core M
	if [[ `sysctl machdep.cpu.brand_string` == *"M-5Y10c"* ]]
	then
		echo "${BLUE}[PRgen]${OFF}: Intel ${BOLD}M-5Y10c${OFF} processor found"
		./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/SSDT-pr.aml ./DSDT/custom/SSDT-pr-m.dsl | tail -1
		prgen=1
	fi	
	if [ $prgen -eq 0 ]
	then
	  echo "${RED}${BOLD}[Warning] Unable to detect model. SSDT-pr.aml will not be generated.${OFF}"
	fi	
	# Rehabman NullEthernet.kext
	echo "${BLUE}[RMNE]${OFF}: Compiling SSDT-rmne to ./DSDT/compiled"
	./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/SSDT-rmne.aml ./DSDT/custom/SSDT-rmne.dsl | tail -1
}

patch_hda()
{
	echo "${GREEN}[HDA]${OFF}: Creating AppleHDA injection kernel extension for ${BOLD}CX20752${OFF}"
	sudo cp -r ./audio/UX305_AppleHDA.kext /System/Library/Extensions
	echo "       --> ${BOLD}Installed UX305_AppleHDA.kext to /System/Library/Extensions${OFF}"
	sudo cp -r ./audio/CodecCommander.kext /System/Library/Extensions
	echo "       --> ${BOLD}Installed CodecCommander.kext to /System/Library/Extensions${OFF}"
}

install_kexts()
{
	patch_hda

	sudo cp -r ./kexts/ACPIBatteryManager.kext /System/Library/Extensions
	echo "       --> ${BOLD}Installed ACPIBatteryManager.kext to /System/Library/Extensions${OFF}"

	sudo cp -r ./kexts/ApplePS2SmartTouchPad.kext /System/Library/Extensions
	echo "       --> ${BOLD}Installed ApplePS2SmartTouchPad.kext to /System/Library/Extensions${OFF}"

	sudo cp -r ./kexts/AsusNBFnKeys.kext /System/Library/Extensions
	echo "       --> ${BOLD}Installed AsusNBFnKeys.kext to /System/Library/Extensions${OFF}"

	sudo cp -r ./kexts/FakePCIID.kext /System/Library/Extensions
	echo "       --> ${BOLD}Installed FakePCIID.kext to /System/Library/Extensions${OFF}"	

	sudo cp -r ./kexts/IntelBacklight.kext /System/Library/Extensions
	echo "       --> ${BOLD}Installed IntelBacklight.kext to /System/Library/Extensions${OFF}"

	sudo cp -r ./kexts/NullEthernet.kext /System/Library/Extensions
	echo "       --> ${BOLD}Installed NullEthernet.kext to /System/Library/Extensions${OFF}"

	sudo cp -r ./kexts/XHCI-9-series.kext /System/Library/Extensions
	echo "       --> ${BOLD}Installed XHCI-9-series.kext to /System/Library/Extensions${OFF}"	
	
	if [[ `ioreg -l | grep PXSX | grep compatible | grep -i pci14e4,43b1` == *"PXSX"* ]]
	then
		echo "${BLUE}[WIFI]${OFF}: ${BOLD}BCM94352HMB${OFF} wireless found"
		sudo cp -r ./kexts/FakePCIID_Broadcom_WiFi.kext /System/Library/Extensions
		echo "       --> ${BOLD}Installed FakePCIID_Broadcom_WiFi.kext to /System/Library/Extensions${OFF}"
		sudo cp -r ./kexts/BrcmPatchRAM2.kext /System/Library/Extensions
		echo "       --> ${BOLD}Installed BrcmPatchRAM2.kext to /System/Library/Extensions${OFF}"
		sudo cp -r ./kexts/BrcmFirmwareRepo.kext /System/Library/Extensions
		echo "       --> ${BOLD}Installed BrcmFirmwareRepo.kext to /System/Library/Extensions${OFF}"				
	fi
	echo "${GREEN}[INFO]${OFF}: Updating system caches..."
	sudo kextcache -system-caches
	sudo kextcache -system-prelinked-kernel
	#One more time just to be safe?
	sudo kextcache -system-caches
}

RETVAL=0

if [[ gID -ne 0 ]];
  then
    clear
    echo "${RED}${BOLD}[Warning] This script must be run as root!${OFF}"
    sudo "$0" "$@"
else
	case "$1" in
		--update)
			git_update
			RETVAL=1
			;;
		--decompile-dsdt)
			decompile_dsdt
			RETVAL=1
			;;
		--compile-dsdt)
			compile_dsdt
			RETVAL=1
			;;
		--patch-dsdt)
			patch_dsdt
			RETVAL=1
			;;
		--install-kexts)
			install_kexts
			RETVAL=1
			;;			
		*)
			clear
			model_detected=0
			if [[ `sysctl machdep.cpu.brand_string` == *"i5-5200U"* ]]
			then
				model_detected=1
				echo "${GREEN}${BOLD}Model Detected: Asus UX305LA (i5-5200U CPU @ 2.20GHz)${OFF}"
			fi
			if [[ `sysctl machdep.cpu.brand_string` == *"M-5Y10c"* ]]
			then
				model_detected=1
				echo "${GREEN}${BOLD}Model Detected: Asus UX305FA (M-5Y10c CPU @ 0.80GHz)${OFF}"
			fi
			if [ $model_detected -eq 0 ]
			then
			  echo "${RED}${BOLD}[Warning] Model not detected. Generated SSDT files and installed kexts will be incomplete.${OFF}"
			fi
			echo "${BOLD}Asus UX305LA/UX305FA${OFF} - El Capitan 10.11 - https://bitbucket.org/spigots/ux305-el-capitan"
			echo
			echo "\t${BOLD}--update${OFF}: Update to latest version"
			echo "\t${BOLD}--decompile-dsdt${OFF}: Decompile DSDT files in ./DSDT/raw"
			echo "\t${BOLD}--patch-dsdt${OFF}: Patch DSDT files in ./DSDT/decompiled"
			echo "\t${BOLD}--compile-dsdt${OFF}: Compile DSDT files to ./DSDT/compiled"
			echo "\t${BOLD}--install-kexts${OFF}: Install necessary kexts to /System/Library/Extensions"
			echo
			echo "${BOLD}Credits:"
			echo "${BLUE}Laptop-DSDT${OFF}: https://github.com/RehabMan/Laptop-DSDT-Patch"
			echo "${BLUE}ssdtPRgen${OFF}: https://github.com/Piker-Alpha/ssdtPRGen.sh"
			echo "${BLUE}AppleHDA CX20752${OFF}: https://github.com/Mirone/AppleHDAPatcher"
			echo "${BLUE}XPS9530-OSX Script${OFF}: https://github.com/the-darkvoid/XPS9530-OSX"
			echo
			RETVAL=1
		    ;;
	esac

	exit $RETVAL
fi
