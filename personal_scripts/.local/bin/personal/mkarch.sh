#!/bin/sh

case $1 in
	tar) tar -cvf $2.tar $pwd$2 ;;
	zip) zip -r $2.zip $pwd$2 ;;
	7z) 7z a $2.7z $pwd$2 ;;
	rar) 7z a $2.rar $pwd$2 ;;
	tgz) tar -cvzf $2.tar.gz $pwd$2 ;;
	-h|--help|*) echo "archiver [ext] [name of archive and destnation file]" ;;
esac
