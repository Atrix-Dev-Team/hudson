#!/usr/bin/python
import sys
import os
int = 0
workspace = os.path.join(os.environ['WORKSPACE'], os.environ['REPO_BRANCH'])
for patch in sys.argv[1].split(','):
	patch = patch.strip().split('|')
	os.system("echo Patching %s from %s ; cd %s ; curl %s | git apply" % (patch[0], patch[1], os.path.join(workspace, patch[0]), patch[1]))
	#os.system("cd %s ; git reset --hard" % (os.path.join(workspace, patch[0])))
	print patch
