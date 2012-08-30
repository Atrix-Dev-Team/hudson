#!/usr/bin/env bash

function check_result {
  if [ "0" -ne "$?" ]
  then
    echo $1 step failed !
    exit 1
  fi
}

if [ -z "$HOME" ]
then
  echo HOME not in environment, guessing...
  export HOME=$(awk -F: -v v="$USER" '{if ($1==v) print $6}' /etc/passwd)
fi

if [ -z "$WORKSPACE" ]
then
  echo WORKSPACE not specified
  exit 1
fi

if [ -z "$CLEAN_TYPE" ]
then
  echo CLEAN_TYPE not specified
  exit 1
fi

if [ -z "$REPO_BRANCH" ]
then
  echo REPO_BRANCH not specified
  exit 1
fi

if [ -z "$LUNCH" ]
then
  echo LUNCH not specified
  exit 1
fi

# colorization fix in Jenkins
export CL_PFX="\"\033[34m\""
export CL_INS="\"\033[32m\""
export CL_RST="\"\033[0m\""

rm -rf $WORKSPACE/archive-kernel
mkdir -p $WORKSPACE/archive-kernel
export BUILD_NO=$BUILD_NUMBER
unset BUILD_NUMBER

export PATH=/mnt/bin:~/bin:$PATH

export USE_CCACHE=1
export CCACHE_NLEVELS=4
export BUILD_WITH_COLORS=0

# make sure ccache is in PATH
export PATH="$PATH:/opt/local/bin/:$PWD/prebuilt/$(uname|awk '{print tolower($0)}')-x86/ccache"

if [ -f ~/.jenkins_profile ]
then
  . ~/.jenkins_profile
fi

HUDSON_DIR=$WORKSPACE/hudson

echo "About to do $HUDSON_DIR/$REPO_BRANCH-setup.sh"
cd $WORKSPACE/$REPO_BRANCH
if [ -f $HUDSON_DIR/$REPO_BRANCH-setup.sh ]
then
  echo "Doing $HUDSON_DIR/$REPO_BRANCH-setup.sh"
  $HUDSON_DIR/$REPO_BRANCH-setup.sh $WORKSPACE $REPO_BRANCH
fi

cd $WORKSPACE/$REPO_BRANCH
echo "We are ready to build in $WORKSPACE/$REPO_BRANCH"

. build/envsetup.sh
lunch $LUNCH
check_result lunch failed.

UNAME=$(uname)

if [ ! -z "$GERRIT_CHANGES" ]
then
  export CM_SNAPSHOT=true
  IS_HTTP=$(echo $GERRIT_CHANGES | grep http)
  if [ -z "$IS_HTTP" ]
  then
    python $WORKSPACE/hudson/repopick.py $GERRIT_CHANGES
    check_result "gerrit picks failed."
  else
    python $WORKSPACE/hudson/repopick.py $(curl $GERRIT_CHANGES)
    check_result "gerrit picks failed."
  fi
fi

if [ ! "$(ccache -s|grep -E 'max cache size'|awk '{print $4}')" = "20.0" ]
then
  ccache -M 20G
fi

rm -f $OUT/boot.img*
make $CLEAN_TYPE

make -j$CORES bootimage
check_result Build failed.

echo "Files in $OUT"
echo "############################################"
ls -l $OUT
echo "############################################"

# Files to keep
cp $OUT/boot.img $WORKSPACE/archive-kernel
cp $OUT/system/lib/modules/*.ko $WORKSPACE/archive-kernel/

$WORKSPACE/hudson/makezip.py /dev/block/mmcblk0p11

chmod -R ugo+r $WORKSPACE/archive-kernel
