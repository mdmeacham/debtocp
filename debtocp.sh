#!/bin/bash

OPTIND=1

usage() { 
	echo "Usage: $0 [OPTIONS] Package.deb"
	echo "OPTIONS include:"
	echo "-i file       :Script file to be added and called by default CP init"
	echo "-d directory  :Directory of extra (in addition to files in deb package) files to be added to CP"
	exit 0
}

EXTRA_INIT=''
EXTRA_DIR=''

while getopts "i:d:" o; do
    case "${o}" in
        i)
            EXTRA_INIT=${OPTARG}
            ;;
        d)
            EXTRA_DIR=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

[ $# -lt 1 ] && usage

DEB_FILE=$1

[ -f $DEB_FILE ] || usage
[ ! -z $EXTRA_INIT ] && [ ! -f $EXTRA_INIT ] && usage
[ ! -z $EXTRA_DIR ] && [ ! -d $EXTRA_DIR ] && usage

VERSION=$(dpkg -I $DEB_FILE | grep Version | sed -e "s/^.*Version: //")
PACKAGE=$(dpkg -I $DEB_FILE | grep Package | sed -e "s/^.*Package: //")
SIZE=$(dpkg -I $DEB_FILE | grep Installed-Size | sed -e "s/^.*Installed-Size: //")
SIZE=$(echo "$SIZE * 1.1" | bc)
SIZE=$(echo "(($SIZE+0.5)/1)/1000" | bc)
echo "Size + 10% is $SIZE"


echo "Creating CP for $VERSION of $PACKAGE"
rm -f ${PACKAGE}_init_script

cat << EOF > ${PACKAGE}_init_script
#!/bin/sh

ACTION="${PACKAGE}_init_script_\${1}"

# mount point path
MP=\$(get custom_partition.mountpoint)
# custom partition path
CP="\${MP}/$PACKAGE"
# output to systemlog with ID amd tag
LOGGER="logger -it \${ACTION}"

echo "Starting" | \$LOGGER

case "\$1" in
init)
	# Initial permissions
	chown -R 0:0 "\${CP}" | \$LOGGER
	chmod 755 "\${MP}" | \$LOGGER
	# Linking files and folders on proper path
	find "\${CP}" | while read LINE
	do
		DEST=\$(echo -n "\${LINE}" | sed -e "s|\${CP}||g")
		if [ ! -z "\${DEST}" -a ! -e "\${DEST}" ]; then
			# Remove the last slash, if it is a dir
			[ -d \$LINE ] && DEST=\$(echo "\${DEST}" | sed -e "s/\/\$//g") | \$LOGGER
			if [ ! -z "\${DEST}" ]; then
				ln -sv "\${LINE}" "\${DEST}" | \$LOGGER
			fi
		fi
	done

	# Run extra initialization
	\${CP}/$(basename $EXTRA_INIT)

;;
stop)
	#killall MYAPPNAME
	#sleep 3
;;
esac

echo "Finished" | \$LOGGER

exit 0
EOF

chmod 755 ${PACKAGE}_init_script
rm -fr $PACKAGE

rm -fr results-$PACKAGE
mkdir results-$PACKAGE

dpkg -x $DEB_FILE $PACKAGE

[ -z $EXTRA_INIT ] || cp -f $EXTRA_INIT ./$PACKAGE

[ -z $EXTRA_DIR ] || cp -a $EXTRA_DIR/* ./$PACKAGE


chmod 755 ./${PACKAGE}/${EXTRA_INIT}
cp ${PACKAGE}_init_script ./$PACKAGE
tar cjvf results-$PACKAGE/$PACKAGE.tar.bz2 $PACKAGE

cat << EOF > results-$PACKAGE/$PACKAGE.inf
[INFO]
[PART]
file="$PACKAGE.tar.bz2"
version="$VERSION"
size="${SIZE}M"
name="$PACKAGE"
minfw="10.05.100".
EOF

exit 0

