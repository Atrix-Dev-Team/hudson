if [ ! -d $WORKSPACE/hudson ]; then
   git clone git://github.com/brandon15811/hudson.git -b defy
fi
cd $WORKSPACE/hudson && git reset --hard && git pull --rebase
rm -rf $WORKSPACE/archive/
mkdir $WORKSPACE/archive
set -e
BUILD_NO=$JOB_NUM
if [ ! -f $JENKINS_HOME/jobs/$DEVICE/builds/$BUILD_NO/archive/archive/cm-*.zip ]
then
	if [ ! -f $JENKINS_HOME/jobs/$DEVICE/builds/$BUILD_NO/archive/archive/update-squished.zip ]
	then
		unset TARGET_UPDATE_FILE
		echo "Update zip not found for current job. Exiting."
		exit 0
	else
		TARGET_UPDATE_FILE=$(basename `ls $JENKINS_HOME/jobs/$DEVICE/builds/$BUILD_NO/archive/archive/update-squished.zip`)
	fi
else
	TARGET_UPDATE_FILE=$(basename `ls $JENKINS_HOME/jobs/$DEVICE/builds/$BUILD_NO/archive/archive/cm-*.zip`)
fi

for job in `find $JENKINS_HOME/jobs/$DEVICE/builds/* -maxdepth 0 -type l`
do
	if [ `basename $job` == "$BUILD_NO" ]
	then
		continue
	fi
	echo "DEBUG: "`basename $job`
	if [ ! -f $JENKINS_HOME/jobs/$DEVICE/builds/`basename $job`/archive/archive/cm-*.zip ]
	then
		
		if [ ! -f $JENKINS_HOME/jobs/$DEVICE/builds/`basename $job`/archive/archive/update-squished.zip ]
		then
			unset SOURCE_UPDATE_FILE
			echo "Update zip not found for job `basename $job`. Skipping."
			continue
		else
			SOURCE_UPDATE_FILE=$(basename `ls $JENKINS_HOME/jobs/$DEVICE/builds/$(basename $job)/archive/archive/update-squished.zip`)
		fi
	else
		SOURCE_UPDATE_FILE=$(basename `ls $JENKINS_HOME/jobs/$DEVICE/builds/$(basename $job)/archive/archive/cm-*.zip`)
	fi
	if [ ! -d $JENKINS_HOME/jobs/$DEVICE/builds/`basename $job`/archive/archive/patch/META/ ]
	then
		echo "Build info for job `basename $job` not found. Skipping."
		continue
	fi
	echo "DEBUG: SOURCE" $SOURCE_UPDATE_FILE
	echo "DEBUG: TARGET" $TARGET_UPDATE_FILE
	cd $WORKSPACE/hudson/patch
	./ota_from_target_files --verbose \
	--info_source=$JENKINS_HOME/jobs/$DEVICE/builds/`basename $job`/archive/archive/patch \
	--info_target=$JENKINS_HOME/jobs/$DEVICE/builds/$BUILD_NO/archive/archive/patch \
	--package_key=security/testkey \
	--incremental_from=$JENKINS_HOME/jobs/$DEVICE/builds/`basename $job`/archive/archive/$SOURCE_UPDATE_FILE \
	$JENKINS_HOME/jobs/$DEVICE/builds/$BUILD_NO/archive/archive/$TARGET_UPDATE_FILE \
	$WORKSPACE/archive/patch-cm-9-`date +%Y%m%d`-NIGHTLY-`basename $job`-to-$BUILD_NO-olympus-signed.zip
	echo "####################################################################################"
	sleep 2
	
	
done
echo hi > hi