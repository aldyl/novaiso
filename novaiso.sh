#!/usr/bin/env bash
set -e

SCRIPT=$(readlink -m $(type -p $0 ))      # Full path to script
PROYECT_BASE=$(dirname "${SCRIPT}")         # Directory script is run in

LOGFILE="tee -a novaiso.log" 

#@Distro Nova @Version 6.0  @CODENAME 2017  @arch x86_64

export DISTRO=$(lsb_release -is)

export VERSION=$(lsb_release -rs)

export CODENAME=$(lsb_release -cs)

export ARCH_LIVECD=$(uname -m)

export SQUASHFS_ROOT_DIRECTORY=squashfs-root

export PATH_TO_ISO_IMG=../nova-escritorio-$VERSION-$ARCH_LIVE.iso

#Installer for Nova
NOVAINSTALLER="nova-escritorio ubiquity-frontend-gtk ubiquity-slideshow" 

#Dont keep after installer
NOINSTALLER="ubiquity ubiquity-frontend-gtk ubiquity-frontend-kde \
        	ubiquity-slideshow casper lupin-casper live-initramfs user-setup discover1 xresprobe \
	        os-prober libdebian-installer4"

#Tools for Rescue live-cd
RESCUE="gparted testdisk wipe partimage xfsprogs reiserfsprogs jfsutils ntfs-3g  dosfstools mtools"

#Tools for disks format and some devices
DISKFS="exfat-fuse exfat-utils hfsplus hfsutils ntfs-3g"

#Tools for Android and Iphone
ANDROIDIPHONE="mtp-tools ipheth-utils ideviceinstaller ifuse"

#Disk temperature Sensors
HDDTEMP="lm-sensors hddtemp"

#Advance Power Save for Laptops
UPSAVE="tlp tlp-rdw"
# Active with sudo tlp start

while read param ; do
eval ${param}
done < ~/.novaisorc

if [ "$ARCH_LIVECD" = "x86_64" ]; then
ARCH_LIVECD=amd64
efi=".efi"
fi

show_default() {
    clear
        echo -e "\e[1;12m********************************************************************************\e[0;49m"
       	echo -e "\e[1;24m###########              isonova make new clean chroot               ###########\e[0;30m"
        echo -e "\e[1;12m********************************************************************************\e[0;32m"
	
    echo -e " "
    echo -e "Distribution =  ${DISTRO}"
    echo -e "Version      = "$VERSION""
    echo -e "Code Name    = "$CODENAME""
    echo -e "Architecture = "$ARCH_LIVECD""
    echo -e "Mirror Repository"
    echo -e ""$MIRRORREPOSITORY""
    echo -e "Components   = "$COMPONENTS""
    echo -e "Debootstrap Chroot = ${SQUASHFS_ROOT_DIRECTORY}"
    echo -e "The default directory for the chroot is the current folder"
}


change_default(){

     echo -e "\e[1;12mThe above information is truly? Y/n \e[0;39m"
     read  ans
   if [ "$ans" = "Y" ] || [ "$ans" = "y" ] || [ "$ans" = "yes" ] || [ "$ans" = "" ]; then
     echo -e " ****Chroot environment configured*****"
   else
     menu
   fi

}

configure_debootstrap() {

	clear
    echo -e "\e[1;12m################################################################################\e[0;39m"
	echo -e "\e[1;12m###########                  Begining Debootstrap                    ###########\e[0;39m"
	echo -e "\e[1;12m################################################################################\e[0;39m"
    
     
    #instalando debootstrap
    sudo apt-get update
    sudo apt-get --yes install debootstrap
    
    #Carpeta para el debootstrap
    sudo rm -R ${SQUASHFS_ROOT_DIRECTORY}
    mkdir -p ${SQUASHFS_ROOT_DIRECTORY}
    #Instalando el debootstrap
    sudo debootstrap --arch=$ARCH_LIVECD --components=$COMPONENTS $CODENAME ${SQUASHFS_ROOT_DIRECTORY} $MIRRORREPOSITORY
    #Sistema listo,

	}

mount_fs_chroot(){
	
	sudo chroot ${SQUASHFS_ROOT_DIRECTORY} mount -t proc proc /proc
    sudo chroot ${SQUASHFS_ROOT_DIRECTORY} mount -t sysfs sysfs /sys
	
	sudo mount --bind /dev ${SQUASHFS_ROOT_DIRECTORY}/dev 
    sudo mount --bind /run ${SQUASHFS_ROOT_DIRECTORY}/run
	

}

umount_fs_chroot(){
	
	sudo umount -f ${SQUASHFS_ROOT_DIRECTORY}/proc
    sudo umount -f ${SQUASHFS_ROOT_DIRECTORY}/sys
    sudo umount -f ${SQUASHFS_ROOT_DIRECTORY}/dev
    sudo umount -f ${SQUASHFS_ROOT_DIRECTORY}/run

	}
	
clean_chroot(){
	
	if [ "$VERSION" = "2015" ]; then
	 
	nova_2015="rm /sbin/inictl 
mv /sbin/initctl.blocked /sbin/inictl
mv /usr/sbin/invoke-rc.d-backup /usr/sbin/invoke-rc.d" 
	
	fi

    cat <<EOF > /tmp/util_clean_chroot.sh
	#!/usr/bin/env bash

	clean_chroot(){

	echo "Update all packages"
	apt-get --yes upgrade

	echo "Clean Chroot"

    $nova_2015
    
	apt-get clean

	find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;

	rm -R /etc/resolv.conf /etc/hostname

	rm -R /var/lib/dbus/machine-id

	rm -rf /tmp/*

	exit
}

echo "Go out chroot"

clean_chroot

		
EOF
		
	sudo cp /tmp/util_clean_chroot.sh ${SQUASHFS_ROOT_DIRECTORY}/opt/
    sudo chroot ${SQUASHFS_ROOT_DIRECTORY} sh /opt/util_clean_chroot.sh
    echo "Finished Clean"
    sudo rm ${SQUASHFS_ROOT_DIRECTORY}/opt/util_clean_chroot.sh

}

install_app_chroot(){
	
	echo "Generate customize script"
	
	if [ "$VERSION" = "2015" ]; then
	 
	nova_2015="mv /sbin/inictl /sbin/initctl.blocked
mv /usr/sbin/invoke-rc.d /usr/sbin/invoke-rc.d-backup
ln -s /bin/true /sbin/initctl
ln -s /bin/true /usr/sbin/invoke-rc.d" 
	
	fi

	cat <<EOF > /tmp/util_chroot_app.sh
	#!/bin/bash

	list_app(){

	apt-get install --yes  $NOVAINSTALLER $RESCUE $DISKFS $ANDROIDIPHONE $HDDTEMP $UPSAVE 	

	echo -e "\e[1;31m********************************************************************************\e[0;39m"
	echo "Finish package list..."
	
	}

      
	custom_app(){

	echo "Fixing packages..."
	apt-get install -f

	echo -e "\e[1;31m********************************************************************************\e[0;39m"
	echo "Update packages"
	apt-get update

	$nova_2015
	
	LANG=
	
	export LC_ALL=C
	
	
	echo -e "\e[1;31m********************************************************************************\e[0;39m"
	echo "DBus..."
	apt-get install --yes dbus

	dbus-uuidgen > /var/lib/dbus/machine-id

	echo -e "\e[1;31m********************************************************************************\e[0;39m"
	echo "Nova Base .."
	apt-get install --yes nova-base

	echo -e "\e[1;31m********************************************************************************\e[0;39m"
	echo "Linux Image..."
	apt-get install --yes casper
	
#   This is for UEFI Secure Boot 	
#	apt-get install --yes linux-generic
    apt-get install --yes linux-signed-generic
	echo -e "\e[1;31m********************************************************************************\e[0;39m"
	
	echo "Fixing packages..."
	apt-get install -f

	list_app
	}

	custom_app
		
EOF
		
	sudo cp /tmp/util_chroot_app.sh ${SQUASHFS_ROOT_DIRECTORY}/opt/
	sudo chroot ${SQUASHFS_ROOT_DIRECTORY} bash /opt/util_chroot_app.sh
	echo "Delete customize script"
	sudo rm ${SQUASHFS_ROOT_DIRECTORY}/opt/util_chroot_app.sh
	
	}
	
install_app(){

	echo  "Set Network Configuration"
	sudo cp /etc/hosts ${SQUASHFS_ROOT_DIRECTORY}/etc/hosts
	
	sudo cp /etc/resolv.conf ${SQUASHFS_ROOT_DIRECTORY}/etc/resolv.conf
	
	componentsMirror=$(echo -e $COMPONENTS | sed s/,/" "/g) 
	  
    sudo echo  "deb $MIRRORREPOSITORY $CODENAME $componentsMirror" > /tmp/sources.list
    sudo cp /tmp/sources.list ${SQUASHFS_ROOT_DIRECTORY}/etc/apt/sources.list
	
	echo "Start app installation"
	mount_fs_chroot

	#In chroot
	install_app_chroot
    clean_chroot

	#Finish chroot
	umount_fs_chroot
	
	echo "Finish app installation"

	}

modify_squashfs(){
	
		
	sudo unsquashfs $PWD/$ARCH_LIVECD/casper/filesystem.squashfs -d $PWD/${SQUASHFS_ROOT_DIRECTORY} 2> /dev/null

	sudo mv $PWD/$ARCH_LIVECD/casper/filesystem.squashfs $PWD/$ARCH_LIVECD/casper/filesystem.squashfs.save 2> /dev/null

	mount_fs_chroot

	sudo chroot $PWD/${SQUASHFS_ROOT_DIRECTORY}/ /bin/bash

	umount_fs_chroot
	
	}

compress_squashfs(){
	
	echo  "Close chroot"

	mount_fs_chroot
	
	clean_chroot

	umount_fs_chroot

    #Create the folder casper if not exist
    mkdir -p  $PWD/$ARCH_LIVECD/casper
	
	sudo mksquashfs \
	$PWD/${SQUASHFS_ROOT_DIRECTORY} $PWD/$ARCH_LIVECD/casper/filesystem.squashfs     \
	-b 1048576 -comp xz -Xdict-size 100%

	sudo rm $PWD/$ARCH_LIVECD/casper/filesystem.squashfs.save 2> /dev/null

}

new_squashfs_for_isoimage(){

	echo  "Create filesystem manifest"

	#Create the folder casper if not exist
    mkdir -p  $PWD/$ARCH_LIVECD/casper
    
	sudo chroot ${SQUASHFS_ROOT_DIRECTORY} dpkg-query -W \
	--showformat='${Package} ${Version}\n'  | tee  $PWD/$ARCH_LIVECD/casper/filesystem.manifest

	cp -v  $PWD/$ARCH_LIVECD/casper/filesystem.manifest  $PWD/$ARCH_LIVECD/casper/filesystem.manifest-desktop

	echo  "Remove installers from filesystem manifest"
	
	REMOVE='$NOINSTALLER  $RESCUE'

	for i in $REMOVE; do
	sed -i "/${i}/d" $PWD/$ARCH_LIVECD/casper/filesystem.manifest-desktop;
	done

	echo  "Filesystem Size"
	printf $(du -sx --block-size=1 $PWD/$ARCH_LIVECD/casper/filesystem.squashfs | \
	cut -f1) > $PWD/$ARCH_LIVECD/casper/filesystem.size

	
	echo "Copiando vmlinux e initrd"

	if [ "$ARCH_LIVECD" = "amd64" ];
	then
		echo  "vmlinux uefi signed"
		sudo cp ${SQUASHFS_ROOT_DIRECTORY}/boot/vmlinuz-*.*.**-**-generic.efi.signed $PWD/$ARCH_LIVECD/casper/vmlinuz"$efi"
	else
	    echo  "vmlinux legacy"
		sudo cp ${SQUASHFS_ROOT_DIRECTORY}/boot/vmlinuz-*.*.**-**-generic $PWD/$ARCH_LIVECD/casper/vmlinuz"$efi"
	fi 

    echo  "Copy initrd"
	sudo cp ${SQUASHFS_ROOT_DIRECTORY}/boot/initrd.img-*.*.**-**-generic $PWD/$ARCH_LIVECD/casper/initrd.lz	

		
	echo -e "\e[1;12mDelete decompresed squashfs-root enviroment Y/n \e[0;39m"
     read  ans
      if [ "$ans" = "Y" ] || [ "$ans" = "y" ] || [ "$ans" = "yes" ] || [ "$ans" = "" ]; then
    
         sudo rm -R ${SQUASHFS_ROOT_DIRECTORY} 
         echo  " ****Chroot environment deleted***** "
  
      fi
	
}

grub_efi(){
	
	mkdir -p $PWD/$ARCH_LIVECD
	
	cp "${PROYECT_BASE}"/grub.tar.lzma $PWD/$ARCH_LIVECD

	cd $PWD/$ARCH_LIVECD
	
	tar --lzma -xvpf grub.tar.lzma > /dev/null
	
	cd ..
	
	rm $PWD/$ARCH_LIVECD/grub.tar.lzma
	
	cat <<EOF >  $PWD/$ARCH_LIVECD/boot/grub/grub.cfg
	
if loadfont /boot/grub/font.pf2 ; then
	set gfxmode=auto
	insmod efi_gop
	insmod efi_uga
	insmod gfxterm
	terminal_output gfxterm
fi

set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "Nova Desktop $VERSION $ARCH_LIVECD" {
	set gfxpayload=keep
        linux	/casper/vmlinuz$efi  boot=casper quiet splash ---
        initrd /casper/initrd.lz
}

EOF
}

iso_linux(){
	
	mkdir -p $PWD/$ARCH_LIVECD
	
	cp "${PROYECT_BASE}"/isolinux.tar.lzma $PWD/$ARCH_LIVECD
	
	cd $PWD/$ARCH_LIVECD
	
	tar --lzma -xvpf isolinux.tar.lzma > /dev/null
	
	cd ..
	
	rm $PWD/$ARCH_LIVECD/isolinux.tar.lzma
	
	cat <<EOF >  $PWD/$ARCH_LIVECD/isolinux/txt.cfg
	
default install
label install
  menu label ^Nova $VERSION $ARCH_LIVECD
  kernel /casper/vmlinuz$efi
  append  boot=casper locale=es_ES initrd=/casper/initrd.lz quiet splash --
label hd
  menu label ^Boot from first hard disk
  localboot 0x80
  
EOF

}

setting_for_boot(){
	
	if [ "$ARCH_LIVECD" = "amd64" ]; then
	 
	grub_efi
	
	else 
	
	mkdir $PWD/$ARCH_LIVECD/boot
	
	cat <<EOF >  $PWD/$ARCH_LIVECD/boot/loopback.cfg
menuentry "Nova Desktop $VERSION $ARCH_LIVECD" {
	set gfxpayload=keep
        linux	/casper/vmlinuz$efi  boot=casper quiet splash ---
        initrd /casper/initrd.lz
}
EOF
	fi
	
	iso_linux
	
	touch $PWD/$ARCH_LIVECD/$DISTRO
	
	mkdir -p $PWD/$ARCH_LIVECD/.disk
	
	cat <<EOF >  $PWD/$ARCH_LIVECD/.disk/base_components
principal
extendido
EOF
	touch  $PWD/$ARCH_LIVECD/.disk/base_installable

	echo -e "full_cd/single" > $PWD/$ARCH_LIVECD/.disk/cd_type

    cat <<EOF >  $PWD/$ARCH_LIVECD/README.diskdefines
#define DISKNAME  Nova $VERSION LTS "$CODENAME" - Release $ARCH_LIVECD
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  i386
#define ARCH  amd64
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF

}

create_iso(){
	
	echo  "Create iso for $ARCH_LIVECD"
	
	echo  "Set 777 permissions"
	sudo chmod 777 -R $PWD/$ARCH_LIVECD

    echo  "Set Volume Name Nova $VERSION $CODENAME - Release $ARCH_LIVECD ($(date +%Y%m%d))"
    
	echo  "Nova $VERSION $CODENAME - Release $ARCH_LIVECD ($(date +%Y%m%d))" > $PWD/$ARCH_LIVECD/.disk/info

    echo  "Computing md5sum for LiveCD"
    
	cd $PWD/$ARCH_LIVECD && find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" > md5sum.txt

	VOLNAME=$DISTRO-$VERSION-$ARCH_LIVECD-$(date +%y%m%d)

	ISOLINUXBIN=isolinux/isolinux.bin 

	ISOLINUXCAT=isolinux/boot.cat

	ISOHYBRIDMBR=isolinux/isohdpfx.bin
	
	EFIBOOT=boot/grub/efi.img 
	
	echo  "Building LiveCD"
	
	if [ "$ARCH_LIVECD" = "amd64" ]; then
	 
    xorriso -as  mkisofs -isohybrid-mbr $ISOHYBRIDMBR -b $ISOLINUXBIN  -c $ISOLINUXCAT -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e $EFIBOOT -no-emul-boot -isohybrid-gpt-basdat -o "$PATH_TO_ISO_IMG" -r "." --sort-weight 0 / --sort-weight 1 /boot -joliet -joliet-long -volid $VOLNAME
	
	else
	
	xorriso -as  mkisofs  -r --sort-weight 0 / --sort-weight 1 /boot -J -l -volid $VOLNAME -b $ISOLINUXBIN -c $ISOLINUXCAT -no-emul-boot -boot-load-size 4 -boot-info-table -o "$PATH_TO_ISO_IMG" .

    fi
    
    cd ..
    
    echo  "LiveCD are ready for use"
}

menu(){
	echo 
	echo
	echo
	echo
	clear
   	echo -e "\e[1;12m********************************************************************************\e[0;39m"
	echo -e "\e[1;12m*\e[0;39m                   Script para crear Personalizaciones de Nova         \e[1;12m*\e[0;39m"
	echo -e "\e[1;12m********************************************************************************\e[0;39m"
	echo -e "\e[1;12mProcesos para crear la personalizacion de NOVA: \e[0;39m"
	echo -e "\e[1;12m	 1 - Proceso Completo\e[0;39m"
	echo -e "\e[1;12m	 2 - Configurar el debootstrap\e[0;39m"
	echo -e "\e[1;12m	 3 - Crear chroot con debootstrap\e[0;39m"
	echo -e "\e[1;12m	 4 - Instalar las app de la Personalizacion \e[0;39m"
	echo -e "\e[1;12m	 5 - Modificar y Actualizar las app de la Personalizacion \e[0;39m"
	echo -e "\e[1;12m	 6 - Comprimir el squashfs.filesystem \e[0;39m"
	echo -e "\e[1;12m	 7 - Crear el Manifiesto del squashfs.filesystem \e[0;39m"
	echo -e "\e[1;12m	 8 - Crear estructura de booteo con grub e isolinux \e[0;39m"
	echo -e "\e[1;12m	 9 - Crear la imagen Iso \e[0;39m"
	echo -e "\e[1;12m	 10 - Salir\e[0;39m"
	echo -e "\e[1;12m-> \e[0;39m"
	read  num
	case $num in
		1)	show_default                      |  $LOGFILE
		    change_default                    |  $LOGFILE
            configure_debootstrap             |  $LOGFILE
            install_app                       |  $LOGFILE
            modify_squashfs                   |  $LOGFILE
            compress_squashfs                 |  $LOGFILE
            new_squashfs_for_isoimage         |  $LOGFILE
            setting_for_boot                  |  $LOGFILE
            create_iso                        |  $LOGFILE
            
    echo -e "\e[1;12m********************************************************************************\e[0;39m"
	echo -e "\e[1;12m*\e[0;39m          			        TERMINADO        		     \e[1;12m*\e[0;39m"
	echo -e "\e[1;12m********************************************************************************\e[0;39m"
			menu
			;;
			
		2)	show_default  |  $LOGFILE
            change_default |  $LOGFILE
			menu
			;;
			
		3)	configure_debootstrap |  $LOGFILE
			menu
			;;
			
		4) 	install_app |  $LOGFILE
			menu
			;;
			
	    5) 	modify_squashfs |  $LOGFILE
			menu
			;;
			
		6)	compress_squashfs |  $LOGFILE
			menu
			;;
		
		7)	new_squashfs_for_isoimage |  $LOGFILE
			menu
			;;
			
		8)	setting_for_boot |  $LOGFILE
			menu
			;;
			
		9)	create_iso |  $LOGFILE
			menu
			;;
		
		10) exit 0
			;;
		*) 	echo "Debe seleccionar una opción válida..."
			clear
			menu
			;;
	esac
}
        date | $LOGFILE
      
        menu 

