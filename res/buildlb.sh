#!/bin/bash -ex

# Being used as a cron job as follows:
# 0 3 * * * root. /etc/profile; /home/user/cloudybuilder.sh > /var/www/images/logs/cloudybuilder.log 2>&1

REPOSITORY=https://github.com/Clommunity/lbmake
IMAGE_PATH=/var/www/images
SUBDIR=unstable
WORKSPACE=${HOME}/lbmake
LBWORKSPACE=devel
ARCH=i386
IMAGE_NAME=cloudy-${ARCH}
IMAGE_EXT=iso
LBIMAGE_NAME=live-image-${ARCH}.hybrid.iso
# USER AND GROUP OF THE $IMAGES_PATH
USER=www-data
GROUP=www-data
BACKUPDAYS=7

make_dirs(){
	mkdir -p ${IMAGE_PATH}/${SUBDIR}
	mkdir -p ${IMAGE_PATH}/${SUBDIR}/old
}

gitpull(){
	# If not exist WORKSPACE/.git need clone
	if [ ! -d "${WORKSPACE}/.git" ];
	then
		git clone ${REPOSITORY} ${WORKSPACE}
	else
		git --git-dir=${WORKSPACE}/.git pull
	fi
}

gitversion(){
	echo $(git --git-dir=${WORKSPACE}/.git rev-parse --short HEAD)
}

clean_workspace(){
	cd ${WORKSPACE} && make clean
}

make_workspace(){
	cd ${WORKSPACE} && make all
	cd ${WORKSPACE} && CNAME=${IMAGE_NAME} make container_tar
}

make_readme(){
	echo "Automatic image generation"
	echo "--------------------------"
	echo "${IMAGE_NAME}.${IMAGE_EXT} (${MD5NF})"
	echo
	echo "Packages:"
	cd ${WORKSPACE} && make describe
	echo "Builder: ${REPOSITORY} (hash:$(gitversion))"
	echo
}

md5_compare(){
	local file1

	file1=$(md5sum $1|cut -d " " -f 1)
	MD5NF=$(md5sum $2|cut -d " " -f 1)

	if [ "$file1" = "$MD5NF" ]
	then
		return 0
	else
		return 1
	fi
}

# Make image
ACTIMG=${IMAGE_PATH}/${SUBDIR}/${IMAGE_NAME}.${IMAGE_EXT}
ACTREADME=${IMAGE_PATH}/${SUBDIR}/${IMAGE_NAME}.README
ACTCONTAINER=${IMAGE_PATH}/${SUBDIR}/${IMAGE_NAME}.container.tar.gz
BUILDIMG=${WORKSPACE}/${LBWORKSPACE}/${LBIMAGE_NAME}
BUILDCONTAINER=${WORKSPACE}/${LBWORKSPACE}/${IMAGE_NAME}.container.tar.gz


make_dirs
[ -d "${WORKSPACE}" ] && clean_workspace
gitpull
make_workspace

if [[ -f ${ACTIMG} ]] && ! md5_compare ${ACTIMG} ${BUILDIMG}
then
	TIMEFILE=$(/usr/bin/stat -c %z ${ACTIMG}|sed 's|[- :]||g'|cut -d "." -f 1)
	TIMEFILE=${TIMEFILE:0:8}
	OLDIMG=${IMAGE_PATH}/${SUBDIR}/old/${IMAGE_NAME}.${TIMEFILE}.${IMAGE_EXT}
	OLDREADME=${IMAGE_PATH}/${SUBDIR}/old/${IMAGE_NAME}.${TIMEFILE}.README
	OLDCONTAINER=${IMAGE_PATH}/${SUBDIR}/old/${IMAGE_NAME}.${TIMEFILE}.container.tar.gz

	mv ${ACTIMG} ${OLDIMG}
	mv ${ACTREADME} ${OLDREADME}
	mv ${ACTCONTAINER} ${OLDCONTAINER}
fi

cp ${BUILDIMG} ${ACTIMG}
cp ${BUILDCONTAINER} ${ACTCONTAINER}
make_readme ${ACTIMG} > ${ACTREADME}

chown -R ${USER}:${GROUP} ${IMAGE_PATH}

# Purge files
OLDPATH=${IMAGE_PATH}/${SUBDIR}/old/

for i in $( ls ${OLDPATH}*.iso ${OLDPATH}*.README ${OLDPATH}*.container.tar.gz| grep -v "$(ls -St ${OLDPATH}*.iso|head -n ${BACKUPDAYS}|sed -e 's/\.iso//')");
do 
	rm -f $i 
done
