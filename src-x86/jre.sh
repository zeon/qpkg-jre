#!/bin/sh

RETVAL=0
QPKG_NAME="JRE"
QPKG_DIR=""

_exit()
{
    /bin/echo -e "Error: $*"
    /bin/echo
    exit 1
}

if [ `/sbin/getcfg ${QPKG_NAME} Enable -u -d FALSE -f /etc/config/qpkg.conf` = UNKNOWN ]; then
	/sbin/setcfg ${QPKG_NAME} Enable TRUE -f /etc/config/qpkg.conf
elif [ `/sbin/getcfg ${QPKG_NAME} Enable -u -d FALSE -f /etc/config/qpkg.conf` != TRUE ]; then
	"${QPKG_NAME} is disabled."
fi

find_base(){
	# Determine BASE installation location according to smb.conf
	BASE=
	publicdir=`/sbin/getcfg Public path -f /etc/config/smb.conf`
	if [ ! -z $publicdir ] && [ -d $publicdir ];then
		publicdirp1=`/bin/echo $publicdir | /bin/cut -d "/" -f 2`
		publicdirp2=`/bin/echo $publicdir | /bin/cut -d "/" -f 3`
		publicdirp3=`/bin/echo $publicdir | /bin/cut -d "/" -f 4`
		if [ ! -z $publicdirp1 ] && [ ! -z $publicdirp2 ] && [ ! -z $publicdirp3 ]; then
			[ -d "/${publicdirp1}/${publicdirp2}/Public" ] && BASE="/${publicdirp1}/${publicdirp2}"
		fi
	fi

	# Determine BASE installation location by checking where the Public folder is.
	if [ -z $BASE ]; then
		for datadirtest in /share/HDA_DATA /share/HDB_DATA /share/HDC_DATA /share/HDD_DATA /share/MD0_DATA; do
			[ -d $datadirtest/Public ] && BASE="/${publicdirp1}/${publicdirp2}"
		done
	fi
	if [ -z $BASE ] ; then
		echo "The Public share not found."
		_exit 1
	fi
	QPKG_DIR="${BASE}/.qpkg/${QPKG_NAME}"
}

create_link(){
	/bin/ln -sf "${QPKG_DIR}/jre" /usr/local/jre
}

remove_link(){
	/bin/rm -rf /usr/local/jre
}

export_java_home(){	
	/bin/cat /etc/profile | /bin/grep "JAVA_HOME" | /bin/grep "/usr/local/jre" 1>>/dev/null 2>>/dev/null
	[ $? -ne 0 ] && /bin/echo "export JAVA_HOME=/usr/local/jre" >> /etc/profile

	/bin/cat /etc/profile | /bin/grep "PATH" | /bin/grep '$JAVA_HOME/bin' 1>>/dev/null 2>>/dev/null 
	[ $? -ne 0 ] && /bin/echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile
}

case "$1" in
  start)
		/bin/echo "Enable Java Runtime Environment... " 
		find_base
		create_link
		export_java_home  
		;;
		
  stop)
		/bin/echo "Disable Java Runtime Environment... "
		remove_link
		/bin/sync
		/bin/sleep 1
		;;
  restart)
		$0 stop
		$0 start
		;;
  *)
		echo "Usage: $0 {start|stop|restart}"
		exit 1
esac

exit $RETVAL

