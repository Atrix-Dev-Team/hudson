WORKSPACE=$1
REPO_BRANCH=$2

echo "Exec'ing vendor/cm/get-prebuilts"
vendor/cm/get-prebuilts

if [ ! -z "$PATCH" ]
then
  $WORKSPACE/hudson/applypatch.py "$PATCH"
fi
if [ ! -z "$CUSTOMPATCH1PATH" ]
then
	cd $WORKSPACE/$REPO_BRANCH/$CUSTOMPATCH1PATH
	echo "Applying Custom Patch 1 to "$CUSTOMPATCH1PATH
	git apply $WORKSPACE/custompatch1.patch
fi

if [ ! -z "$CUSTOMPATCH2PATH" ]
then
	cd $WORKSPACE/$REPO_BRANCH/$CUSTOMPATCH2PATH
	echo "Applying Custom Patch 2 to "$CUSTOMPATCH2PATH
	git apply $WORKSPACE/custompatch2.patch
fi
