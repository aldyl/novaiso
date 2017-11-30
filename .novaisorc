#@Distro Nova @Version 6.0  @code_name 2017  @arch x86_64

DISTRO=$(lsb_release -is)

VERSION=$(lsb_release -rs)

code_name=$(lsb_release -cs)

arch=$(uname -m)

#Repository Mirrors, the first is default.

mirror_repository=( http://10.128.60.100/nova/2017_prueba                  \
                    http://10.53.4.24/nova/2017                     \
                    http://10.128.60.100/nova/2017_prueba            \
                    http://10.128.60.100/nova/2017                    \
                    http://10.128.60.100/nova/2015 )

components="principal,extendido"
componentsMirror="principal extendido"

#Directory for make squashfs

ARCH_LIVE=$arch

squashfs_root_directory=squashfs-root

#Where save the iso-image

PATH_TO_ISO_IMG=../nova-escritorio-$VERSION-$ARCH_LIVE.iso

NOVAINSTALLER="nova-escritorio ubiquity-frontend-gtk ubiquity-slideshow" 

NOINSTALLER="ubiquity ubiquity-frontend-gtk ubiquity-frontend-kde \
        	ubiquity-slideshow casper lupin-casper live-initramfs user-setup discover1 xresprobe \
	        os-prober libdebian-installer4"

RESCUE="gparted testdisk wipe partimage xfsprogs reiserfsprogs jfsutils ntfs-3g  dosfstools mtools"
