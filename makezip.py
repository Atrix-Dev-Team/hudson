#!/usr/bin/python
import zipfile
import glob
import sys
import os
import datetime

lunch = os.environ['LUNCH']
date = datetime.date.today().strftime('%m-%d-%Y')
build_no = os.environ['BUILD_NO']
archive = os.path.join(os.environ['WORKSPACE'], 'archive-kernel')

zf = zipfile.ZipFile(os.path.join(archive, 'kernel-%s-%s-%s.zip' % (lunch, date, build_no)), mode='w')
zf.write(os.path.join(archive, "boot.img"), arcname="boot.img")
zf.write(os.path.join(os.environ['WORKSPACE'], "hudson", "update-binary"), arcname="META-INF/com/google/android/update-binary")
for module in glob.glob("*.ko"):
	#print module
	zf.write(os.path.join(archive, module), arcname="system/lib/modules/" + module)

script = 'ui_print("%s - %s - %s"); \n \
ui_print(" "); \n \
ui_print("Extracting Modules..."); \n \
set_progress(0.25); \n \
run_program("/sbin/busybox", "mount", "/system"); \n \
package_extract_dir("system", "/system"); \n \
unmount("/system"); \n \
set_progress(0.50); \n \
ui_print("Extracting Kernel files..."); \n \
package_extract_file("boot.img", "/tmp"); \n \
ui_print("Writing Boot Image..."); \n \
set_progress(0.75); \n \
run_program("/sbin/busybox", "dd", "if=/dev/zero", "of=%s"); \n \
run_program("/sbin/busybox", "dd", "if=/tmp/boot.img", "of=%s"); \n \
set_progress(1.000000);'  % (lunch, date, build_no, sys.argv[1], sys.argv[1],)
#print script
zf.writestr("META-INF/com/google/android/updater-script", script)

zf.close()

print "Zip Complete!"
