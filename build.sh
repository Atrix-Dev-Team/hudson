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

if [ -z "$RELEASE_TYPE" ]
then
  echo RELEASE_TYPE not specified
  exit 1
fi

# colorization fix in Jenkins
export CL_PFX="\"\033[34m\""
export CL_INS="\"\033[32m\""
export CL_RST="\"\033[0m\""

cd $WORKSPACE
rm -rf archive
mkdir -p archive
export BUILD_NO=$BUILD_NUMBER
unset BUILD_NUMBER
export CM_EXTRAVERSION=$BUILD_NO

export PATH=/mnt/bin:~/bin:$PATH

export USE_CCACHE=1
export BUILD_WITH_COLORS=0

#REPO=$(which repo)
if [ -z "$REPO" ]
then
  mkdir -p ~/bin
  curl https://dl-ssl.google.com/dl/googlesource/git-repo/repo > ~/bin/repo
  chmod a+x ~/bin/repo
fi

# git config --global user.name $(whoami)@$NODE_NAME
# git config --global user.email jenkins@cyanogenmod.com

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
check_result "lunch failed."

rm -f $OUT/cm-*.zip*

UNAME=$(uname)
if [ "$RELEASE_TYPE" = "CM_NIGHTLY" ]
then
  if [ "$REPO_BRANCH" = "gingerbread" ]
  then
    export CYANOGEN_NIGHTLY=true
  else
    export CM_NIGHTLY=true
  fi
elif [ "$RELEASE_TYPE" = "CM_EXPERIMENTAL" ]
then
  export CM_EXPERIMENTAL=true
elif [ "$RELEASE_TYPE" = "CM_RELEASE" ]
then
  if [ "$REPO_BRANCH" = "gingerbread" ]
  then
    export CYANOGEN_RELEASE=true
  else
    export CM_RELEASE=true
  fi
fi

if [ ! -z "$CM_EXTRAVERSION" ]
then
  export CM_EXPERIMENTAL=true
fi

if [ ! -z "$GERRIT_CHANGES" ]
then
  export CM_EXPERIMENTAL=true
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

rm -f $OUT/*.zip*
make $CLEAN_TYPE

mka bacon bacon recoveryzip recoveryimage checkapi
check_result "Build failed."

echo "Files in $OUT"
echo "############################################"
ls -l $OUT
echo "############################################"

# Files to keep
find $OUT/*.zip* | grep ota | xargs rm -f
cp $OUT/cm-*.zip* $WORKSPACE/archive
if [ -d $OUT/obj/PACKAGING/target_files_intermediates/cm_*-target_files-eng.*/ ]
then
  cp -r $OUT/obj/PACKAGING/target_files_intermediates/cm_*-target_files-eng.*/META/filesystem_config.txt $WORKSPACE/archive/
fi
if [ -f $OUT/utilties/update.zip ]
then
  cp $OUT/utilties/update.zip $WORKSPACE/archive/recovery.zip
fi
if [ -f $OUT/recovery.img ]
then
  cp $OUT/recovery.img $WORKSPACE/archive
fi


# archive the build.prop as well
ZIP=$(ls $WORKSPACE/archive/cm-*.zip)
unzip -p $ZIP system/build.prop > $WORKSPACE/archive/build.prop

chmod -R ugo+r $WORKSPACE/archive
