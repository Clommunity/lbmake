#!/bin/bash -ex

# Being used as a cron job as follows:
# 0 3 * * * root. /etc/profile; /home/repo/buildlb.sh > /var/www/images/logs/buildlb.log 2>&1

GP=/var/www/
IMAGE_PATH=images
WORKSPACE=lbmake
REPOSITORY=https://github.com/agustim/lbmake
IMAGE_NAME=cloudy
IMAGE_EXT=iso
LBIMAGE_NAME=binary.hybrid.iso
LBWORKSPACE=devel
USER=www-data
GROUP=www-data
SUBDIR=unstable
BACKUPDAYS=7

make_dirs(){
	mkdir -p ${GP}${IMAGE_PATH}/${SUBDIR}
	mkdir -p ${GP}${IMAGE_PATH}/${SUBDIR}/old
}

gitpull(){
	# If not exist WORKSPACE/.git need clone
	if [ ! -d "${GP}${WORKSPACE}/.git" ];
	then
		git clone ${REPOSITORY} ${GP}${WORKSPACE}
	else
		git --git-dir=${GP}${WORKSPACE}/.git pull
	fi
}	

gitversion(){
	echo $(git --git-dir=${GP}${WORKSPACE}/.git rev-parse --short HEAD)
}

clean_workspace(){
	cd ${GP}${WORKSPACE} && make clean
}

make_workspace(){
	cd ${GP}${WORKSPACE} && make all	
	cd ${GP}${WORKSPACE} && CNAME=${IMAGE_NAME} make container_tar
}

make_readme(){
	echo "Automatic image generation"
	echo "--------------------------"
	echo "${IMAGE_NAME}.${IMAGE_EXT} (${MD5NF})"
	echo
	echo "Packages:"
	cd ${GP}${WORKSPACE} && make describe
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
ACTIMG=${GP}${IMAGE_PATH}/${SUBDIR}/${IMAGE_NAME}.${IMAGE_EXT}
ACTREADME=${GP}${IMAGE_PATH}/${SUBDIR}/${IMAGE_NAME}.README
ACTCONTAINER=${GP}${IMAGE_PATH}/${SUBDIR}/${IMAGE_NAME}.container.tar.gz
BUILDIMG=${GP}${WORKSPACE}/${LBWORKSPACE}/${LBIMAGE_NAME}
BUILDCONTAINER=${GP}${WORKSPACE}/${LBWORKSPACE}/${IMAGE_NAME}.container.tar.gz


make_dirs
[ -d "${GP}${WORKSPACE}" ] && clean_workspace
gitpull
make_workspace

if [[ -f ${ACTIMG} ]] && ! md5_compare ${ACTIMG} ${BUILDIMG}
then
	TIMEFILE=$(/usr/bin/stat -c %z ${ACTIMG}|sed 's|[- :]||g'|cut -d "." -f 1)
	TIMEFILE=${TIMEFILE:0:8}
	OLDIMG=${GP}${IMAGE_PATH}/${SUBDIR}/old/${IMAGE_NAME}.${TIMEFILE}.${IMAGE_EXT}
	OLDREADME=${GP}${IMAGE_PATH}/${SUBDIR}/old/${IMAGE_NAME}.${TIMEFILE}.README
	OLDCONTAINER=${GP}${IMAGE_PATH}/${SUBDIR}/old/${IMAGE_NAME}.${TIMEFILE}.container.tar.gz
	
	mv ${ACTIMG} ${OLDIMG}
	mv ${ACTREADME} ${OLDREADME}
	mv ${ACTCONTAINER} ${OLDCONTAINER}
fi

cp ${BUILDIMG} ${ACTIMG}	
cp ${BUILDCONTAINER} ${ACTCONTAINER}
make_readme ${ACTIMG} > ${ACTREADME}

chown -R ${USER}:${GROUP} ${GP}${IMAGE_PATH}

# Purge files
OLDPATH=${GP}${IMAGE_PATH}/${SUBDIR}/old/

for i in $( ls ${OLDPATH}*.iso ${OLDPATH}*.README ${OLDPATH}*.container.tar.gz| grep -v "$(ls -St ${OLDPATH}*.iso|head -n ${BACKUPDAYS}|sed -e 's/\.iso//')"); 
do 
	rm -f $i 
done
