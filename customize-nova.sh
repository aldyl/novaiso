#!/usr/bin/env bash

while read param ; do
eval ${param}
done < configure.sh

if [ "$arch" = "x86_64" ]; then
arch=amd64
efi=".efi"
fi

show_default(){
        echo "[1;12m********************************************************************************[0;39m"
       	echo "[1;24m###########                         Make a Chroot                    ###########[0;30m"
        echo "[1;12m********************************************************************************[0;32m"
	
    echo " "
    echo "Distribution = ${DISTRO}"
    echo "Version      = "$VERSION""
    echo "Code Name    = "$code_name""
    echo "Architecture = "$arch""
    echo "Production Repository"
    echo ""$mirror_repository""
    echo "Components   = "$components""
    echo "Debootstrap Chroot = ${squashfs_root_directory}"

}

setCodeName(){
     echo "Select Code Name"
     echo "1- 2017"
     echo "2- 2015"
      read  cn
      case $cn in

       1) code_name="2017"
          VERSION="6.0"
           ;;
       2) code_name="2015"
          VERSION="5.0"
           ;;
       *)  echo "You must select a valid option ..."
			clear
			setCodeName
			;;
	esac

}

setArchitecture(){
     echo "Select Architecture"
     echo "1- 64 bits"
     echo "2- 32 bits"
      read  cn
      case $cn in

       1) arch="amd64"
          ARCH_LIVE=$arch
           ;;
       2) arch="i386"
          ARCH_LIVE=$arch
           ;;
       *)  echo "You must select a valid option ..."
			clear
			setArchitecture
			;;
	esac

}

setMirror(){
   
    echo "Select Mirror Number"
    i=0 
    for item in ${mirror_repository[*]};
    do
        printf "$i-  %s\n" $item
        ((i++))
    done

       read  cn
     
    mirror_repository=${mirror_repository[$cn]}

}

setDirectory(){
      echo "The default directory for the chroot is the current folder"
      echo "Type the new address if you want to change and press ENTER"
      read  cn
      if [ "$cn" != "" ] ; then
        echo "New direction: "$cn""
        squashfs_root_directory=$cn
	  fi

}

change_default(){

     echo "[1;12mThe above information is truly? Y/n [0;39m"
     read  ans
   if [ "$ans" = "Y" ] || [ "$ans" = "y" ] || [ "$ans" = "yes" ] || [ "$ans" = "" ]; then
     echo " ****Chroot environment configured*****"
   else
     clear
     setCodeName
     clear
     setArchitecture
     clear
     setMirror
     clear
     setDirectory
     clear
     show_default
     change_default
   fi

}

configure_debootstrap() {
#Se instalan los paquetes esenciales para realizar la personalizacion
	clear
    echo "[1;12m################################################################################[0;39m"
	echo "[1;12m###########           Crear sistema limpio con Debootstrap           ###########[0;39m"
	echo "[1;12m################################################################################[0;39m"
    
     
    #instalando debootstrap
    sudo apt-get update
    sudo apt-get --yes install debootstrap
    #Carpeta para el debootstrap
    sudo rm -R ${squashfs_root_directory}
    mkdir -p ${squashfs_root_directory}
    #Instalando el debootstrap
    sudo debootstrap --arch=$arch --components=$components $code_name ${squashfs_root_directory} $mirror_repository
    #Sistema listo,

	}

mount_fs_chroot(){
	
	sudo chroot ${squashfs_root_directory} mount -t proc proc /proc
    sudo chroot ${squashfs_root_directory} mount -t sysfs sysfs /sys
	
	sudo mount --bind /dev ${squashfs_root_directory}/dev 
    sudo mount --bind /run ${squashfs_root_directory}/run
	

}

umount_fs_chroot(){
	
	sudo umount -f ${squashfs_root_directory}/proc
    sudo umount -f ${squashfs_root_directory}/sys
    sudo umount -f ${squashfs_root_directory}/dev
    sudo umount -f ${squashfs_root_directory}/run

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

	echo "Actualizar todos los paquetes de la distribucion"
	apt-get --yes upgrade

	echo "Limpieza del Chroot"

    $nova_2015
    
	apt-get clean

	find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;

	rm -R /etc/resolv.conf /etc/hostname

	rm -R /var/lib/dbus/machine-id

	rm -rf /tmp/*

	exit
}

echo "Saliendo del Chroot"

clean_chroot

		
EOF
		
	sudo cp /tmp/util_clean_chroot.sh ${squashfs_root_directory}/opt/
    sudo chroot ${squashfs_root_directory} sh /opt/util_clean_chroot.sh
    echo "Limpieza terminada"
    sudo rm ${squashfs_root_directory}/opt/util_clean_chroot.sh

}

install_app_chroot(){
	
	echo "Generando ordenes de personalizacion"
	
	if [ "$VERSION" = "2015" ]; then
	 
	nova_2015="mv /sbin/inictl /sbin/initctl.blocked
mv /usr/sbin/invoke-rc.d /usr/sbin/invoke-rc.d-backup
ln -s /bin/true /sbin/initctl
ln -s /bin/true /usr/sbin/invoke-rc.d" 
	
	fi

	cat <<EOF > /tmp/util_chroot_app.sh
	#!/bin/bash

	#Programs
	NOVAINSTALLER=$NOVAINSTALLER
	RESCUE=$RESCUE
	
	list_app(){

	apt-get install --yes  $NOVAINSTALLER $RESCUE	

	echo "[1;31m********************************************************************************[0;39m"
	echo "Terminada la lista de paquetes..."
	
	}

      
	custom_app(){

	echo "Corrigiendo errores..."
	apt-get install -f

	echo "[1;31m********************************************************************************[0;39m"
	echo "Actualizando los Paquetes"
	apt-get update

	$nova_2015
	
	LANG=
	
	export LC_ALL=C
	
	
	echo "[1;31m********************************************************************************[0;39m"
	echo "DBus..."
	apt-get install --yes dbus

	dbus-uuidgen > /var/lib/dbus/machine-id

	echo "[1;31m********************************************************************************[0;39m"
	echo "Instalando Nova Base"
	apt-get install --yes nova-base

	echo "[1;31m********************************************************************************[0;39m"
	echo "Linux Image..."
	apt-get install --yes casper
	apt-get install --yes linux-generic
	echo "[1;31m********************************************************************************[0;39m"
	echo "Corrigiendo errores..."
	apt-get install -f

	list_app
	}

	custom_app
		
EOF
		
	sudo cp /tmp/util_chroot_app.sh ${squashfs_root_directory}/opt/
	sudo chroot ${squashfs_root_directory} sh /opt/util_chroot_app.sh
	echo "Eliminando comando de personalizacion"
	sudo rm ${squashfs_root_directory}/opt/util_chroot_app.sh
	
	}
	
install_app(){

	echo "Set Network Configuration"
	sudo cp /etc/hosts ${squashfs_root_directory}/etc/hosts
	
	sudo cp /etc/resolv.conf ${squashfs_root_directory}/etc/resolv.conf
	  
    sudo echo "deb $mirror_repository $code_name $componentsMirror" > /tmp/sources.list
    sudo cp /tmp/sources.list ${squashfs_root_directory}/etc/apt/sources.list
	
	echo "Comenzar a Modificar"
	mount_fs_chroot

	#Aqui se ejecuta dentro del chroot
	install_app_chroot
    clean_chroot

	#Se ha terminado el chroot
	umount_fs_chroot

	}

modify_squashfs(){
	
	sudo unsquashfs ${ARCH_LIVE}/casper/filesystem.squashfs -d ${squashfs_root_directory}

	sudo mv $ARCH_LIVE/casper/filesystem.squashfs $ARCH_LIVE/casper/filesystem.squashfs.save

	mount_fs_chroot

	sudo chroot ${squashfs_root_directory}/ /bin/bash

	umount_fs_chroot
	
	}

compress_squashfs(){
	
	echo "Generando ordenes de cierre"

	mount_fs_chroot
	
	clean_chroot

	umount_fs_chroot

    #Create the folder casper if not exist
    mkdir -p  $ARCH_LIVE/casper
	
	sudo mksquashfs \
	${squashfs_root_directory} $ARCH_LIVE/casper/filesystem.squashfs     \
	-b 1048576 -comp xz -Xdict-size 100%

	sudo rm $ARCH_LIVE/casper/filesystem.squashfs.save

}

new_squashfs_for_isoimage(){

	echo "Create filesystem manifest"

	#Create the folder casper if not exist
    mkdir -p  $ARCH_LIVE/casper
    
	sudo chroot ${squashfs_root_directory} dpkg-query -W \
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

	sudo cp ${squashfs_root_directory}/boot/vmlinuz-*.*.**-**-generic $ARCH_LIVE/casper/vmlinuz"$efi"

	sudo cp ${squashfs_root_directory}/boot/initrd.img-*.*.**-**-generic $ARCH_LIVE/casper/initrd.lz	

	sudo cp ${squashfs_root_directory}/boot/memtest86+.bin $ARCH_LIVE/casper/memtest86+.bin
	
	echo "[1;12mDelete squashfs-root enviroment Y/n [0;39m"
     read  ans
   if [ "$ans" = "Y" ] || [ "$ans" = "y" ] || [ "$ans" = "yes" ] || [ "$ans" = "" ]; then
    
     sudo rm -R ${squashfs_root_directory} 
     echo " ****Chroot environment deleted*****"
  
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
	
	mkdir -p $ARCH_LIVE/.disk
	
	cat <<EOF >  $ARCH_LIVE/.disk/base_components
principal
extendido
EOF
	touch  $ARCH_LIVE/.disk/base_installable

	cecho "full_cd/single" > $ARCH_LIVE/.disk/cd_type

    cat <<EOF >  $ARCH_LIVE/README.diskdefines
#define DISKNAME  Nova $VERSION LTS "$code_name" - Release $ARCH_LIVE
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
	
	echo "Create iso for $ARCH_LIVE"
	sudo chmod 777 -R $ARCH_LIVE

	echo "Nova $VERSION $code_name - Release $ARCH_LIVE ($(date +%Y%m%d))" > $ARCH_LIVE/.disk/info

	cd $ARCH_LIVE && find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" > md5sum.txt

	VOLNAME=Nova-$VERSION-$ARCH_LIVE-$(date +%y%m%d)

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
   	echo "[1;12m********************************************************************************[0;39m"
	echo "[1;12m*[0;39m                   Script para crear Personalizaciones de Nova         [1;12m*[0;39m"
	echo "[1;12m********************************************************************************[0;39m"
	echo "[1;12mProcesos para crear la personalizacion de NOVA: [0;39m"
	echo "[1;12m	 1 - Proceso Completo[0;39m"
	echo "[1;12m	 2 - Configurar el debootstrap[0;39m"
	echo "[1;12m	 3 - Crear chroot con debootstrap[0;39m"
	echo "[1;12m	 4 - Instalar las app de la Personalizacion [0;39m"
	echo "[1;12m	 5 - Modificar y Actualizar las app de la Personalizacion [0;39m"
	echo "[1;12m	 6 - Comprimir el squashfs.filesystem [0;39m"
	echo "[1;12m	 7 - Crear el Manifiesto del squashfs.filesystem [0;39m"
	echo "[1;12m	 8 - Crear estructura de booteo con grub e isolinux [0;39m"
	echo "[1;12m	 9 - Crear la imagen Iso [0;39m"
	echo "[1;12m	 10 - Salir[0;39m"
	read -p "[1;12m-> [0;39m" num
	case $num in
		1)	show_default
            change_default
            configure_debootstrap
            install_app
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
		
		10) 	exit 0
			;;
		*) 	echo "Debe seleccionar una opción válida..."
			clear
			menu
			;;
	esac
}

menu
