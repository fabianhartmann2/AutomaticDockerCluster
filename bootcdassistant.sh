#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

dumpiso() {
	iso=$1
	randomfolder=$(echo $RANDOM)
	mkdir -p /mnt/$randomfolder
	mount -o loop $iso /mnt/$randomfolder
	mkdir -p /opt/$randomfolder
	cp -rT /mnt/$randomfolder /opt/$randomfolder
	chmod -R 777 /opt/$randomfolder
	echo Files have been placet into: /opt/$randomfolder/
}

createiso() {
	src=$1
	name=$2
	dest=$3
  cd $dest
	sudo mkisofs -D -r -V "$name" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $dest $src
}

case $1 in
	dump )
		dumpiso $2
		;;
	create )
		createiso $2 $3 $4
		;;
	*)
		echo "################################################"
		echo "# NOTHING SPECIFIED - WHAT DO YOU WANT TO DO?  #"
		echo "################################################"
		echo "* Specify what you want to do: dump | create   *"
		echo "* dump {Path to ISO}                           *"
		echo "* create {Path to dumped folder} {Name for CD} {destination folder} *"
		echo "************************************************"
		;;
esac
