#!/usr/bin/env bash

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

show_default(){
    clear
        echo -e "\e[1;12m********************************************************************************\e[0;39m"
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
	
	sudo unsquashfs ${ARCH_LIVE}/casper/filesystem.squashfs -d ${SQUASHFS_ROOT_DIRECTORY}

	sudo mv ${ARCH_LIVE}/casper/filesystem.squashfs $ARCH_LIVE/casper/filesystem.squashfs.save

	mount_fs_chroot

	sudo chroot ${SQUASHFS_ROOT_DIRECTORY}/ /bin/bash

	umount_fs_chroot
	
	}

compress_squashfs(){
	
	echo  "Close chroot"

	mount_fs_chroot
	
	clean_chroot

	umount_fs_chroot

    #Create the folder casper if not exist
    mkdir -p  $ARCH_LIVE/casper
	
	sudo mksquashfs \
	${SQUASHFS_ROOT_DIRECTORY} $ARCH_LIVE/casper/filesystem.squashfs     \
	-b 1048576 -comp xz -Xdict-size 100%

	sudo rm $ARCH_LIVE/casper/filesystem.squashfs.save

}

new_squashfs_for_isoimage(){

	echo  "Create filesystem manifest"

	#Create the folder casper if not exist
    mkdir -p  $ARCH_LIVE/casper
    
	sudo chroot ${SQUASHFS_ROOT_DIRECTORY} dpkg-query -W \
	--showformat='${Package} ${Version}\n'  | tee  $ARCH_LIVE/casper/filesystem.manifest

	cp -v  $ARCH_LIVE/casper/filesystem.manifest  $ARCH_LIVE/casper/filesystem.manifest-desktop

	REMOVE='$NOINSTALLER  $RESCUE'

	for i in $REMOVE; do
	sed -i "/${i}/d" $ARCH_LIVE/casper/filesystem.manifest-desktop;
	done

	printf $(du -sx --block-size=1 $ARCH_LIVE/casper/filesystem.squashfs | \
	cut -f1) > $ARCH_LIVE/casper/filesystem.size

	
	echo "Copiando vmlinux e initrd"

	if [ "$ARCH_LIVE" = "amd64" ];
	then
	efi=".efi"
	else
	efi=""
	fi 

	sudo cp ${SQUASHFS_ROOT_DIRECTORY}/boot/vmlinuz-*.*.**-**-generic $ARCH_LIVE/casper/vmlinuz"$efi"

	sudo cp ${SQUASHFS_ROOT_DIRECTORY}/boot/initrd.img-*.*.**-**-generic $ARCH_LIVE/casper/initrd.lz	

		
	echo -e "\e[1;12mDelete decompresed squashfs-root enviroment Y/n \e[0;39m"
     read  ans
   if [ "$ans" = "Y" ] || [ "$ans" = "y" ] || [ "$ans" = "yes" ] || [ "$ans" = "" ]; then
    
     sudo rm -R ${SQUASHFS_ROOT_DIRECTORY} 
     echo  " ****Chroot environment deleted***** "
  
   fi
	
}

grub_efi(){
	
	mkdir -p $ARCH_LIVE
	
	cp grub.tar.lzma $ARCH_LIVE

	cd $ARCH_LIVE
	
	tar --lzma -xvpf grub.tar.lzma 
	
	cd ..
	
	rm $ARCH_LIVE/grub.tar.lzma
	
	cat <<EOF >  $ARCH_LIVE/boot/grub/grub.cfg
	
if loadfont /boot/grub/font.pf2 ; then
	set gfxmode=auto
	insmod efi_gop
	insmod efi_uga
	insmod gfxterm
	terminal_output gfxterm
fi

set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "Nova Desktop $VERSION $ARCH_LIVE" {
	set gfxpayload=keep
        linux	/casper/vmlinuz$efi  boot=casper quiet splash ---
        initrd /casper/initrd.lz
}

EOF
}

iso_linux(){
	
	mkdir -p $ARCH_LIVE
	
	cp isolinux.tar.lzma $ARCH_LIVE
	
	cd $ARCH_LIVE
	
	tar --lzma -xvpf isolinux.tar.lzma 
	
	cd ..
	
	rm $ARCH_LIVE/isolinux.tar.lzma
	
	cat <<EOF >  $ARCH_LIVE/isolinux/txt.cfg
	
default install
label install
  menu label ^Nova $VERSION $ARCH_LIVE
  kernel /casper/vmlinuz$efi
  append  boot=casper locale=es_ES initrd=/casper/initrd.lz quiet splash --
label hd
  menu label ^Boot from first hard disk
  localboot 0x80
  
EOF

}

setting_for_boot(){
	
	if [ "$ARCH_LIVE" = "amd64" ]; then
	 
	grub_efi
	
	else 
	mkdir $ARCH_LIVE/boot
	
	cat <<EOF >  $ARCH_LIVE/boot/loopback.cfg
menuentry "Nova Desktop $VERSION $ARCH_LIVE" {
	set gfxpayload=keep
        linux	/casper/vmlinuz$efi  boot=casper quiet splash ---
        initrd /casper/initrd.lz
}
EOF
	fi
	
	iso_linux
	
	touch $DISTRO
	
	mkdir -p $ARCH_LIVE/.disk
	
	cat <<EOF >  $ARCH_LIVE/.disk/base_components
principal
extendido
EOF
	touch  $ARCH_LIVE/.disk/base_installable

	cecho -e "full_cd/single" > $ARCH_LIVE/.disk/cd_type

    cat <<EOF >  $ARCH_LIVE/README.diskdefines
#define DISKNAME  Nova $VERSION LTS "$CODENAME" - Release $ARCH_LIVE
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
	
	echo  "Create iso for $ARCH_LIVE"
	sudo chmod 777 -R $ARCH_LIVE

	echo  "Nova $VERSION $CODENAME - Release $ARCH_LIVE ($(date +%Y%m%d))" > $ARCH_LIVE/.disk/info

	cd $ARCH_LIVE && find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" > md5sum.txt

	VOLNAME=$DISTRO-$VERSION-$ARCH_LIVE-$(date +%y%m%d)

	ISOLINUXBIN=isolinux/isolinux.bin 

	ISOLINUXCAT=isolinux/boot.cat

	ISOHYBRIDMBR=isolinux/isohdpfx.bin
	
	EFIBOOT=boot/grub/efi.img 
	
	if [ "$ARCH_LIVE" = "amd64" ]; then
	 
    xorriso -as  mkisofs -isohybrid-mbr $ISOHYBRIDMBR -b $ISOLINUXBIN  -c $ISOLINUXCAT -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e $EFIBOOT -no-emul-boot -isohybrid-gpt-basdat -o "$PATH_TO_ISO_IMG" -r "." --sort-weight 0 / --sort-weight 1 /boot -joliet -joliet-long -volid $VOLNAME
	
	else
	
	xorriso -as  mkisofs  -r --sort-weight 0 / --sort-weight 1 /boot -J -l -volid $VOLNAME -b $ISOLINUXBIN -c $ISOLINUXCAT -no-emul-boot -boot-load-size 4 -boot-info-table -o "$PATH_TO_ISO_IMG" .

    fi
    
    cd ..
}

menu(){
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
		1)	show_default
		    change_default
            configure_debootstrap
            install_app
            modify_squashfs
            compress_squashfs
            new_squashfs_for_isoimage
            setting_for_boot
            create_iso
            
    echo -e "\e[1;12m********************************************************************************\e[0;39m"
	echo -e "\e[1;12m*\e[0;39m          			        TERMINADO        		     \e[1;12m*\e[0;39m"
	echo -e "\e[1;12m********************************************************************************\e[0;39m"
			menu
			;;
			
		2)	show_default
            change_default
			menu
			;;
			
		3)	configure_debootstrap
			menu
			;;
			
		4) 	install_app
			menu
			;;
			
	    5) 	modify_squashfs
			menu
			;;
			
		6)	compress_squashfs
			menu
			;;
		
		7)	new_squashfs_for_isoimage
			menu
			;;
			
		8)	setting_for_boot
			menu
			;;
			
		9)	create_iso
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

menu
