#!/usr/bin/python2

import requests
import json
import os
import re
import sys

if len(sys.argv) != 2:
  print "You done goofed! This takes exactly one argument: the device lunch combo"
  sys.exit(1)

device = sys.argv[1]
device = re.sub('^cm_','',device,1)
device = re.sub('-[^-]*$','',device,1)

if len(device) <= 0:
  print "No device left after parsing input?"
  sys.exit(2)

resp = requests.get(os.environ['JOB_URL'] + "api/json?tree=builds[timestamp]")

jsonreply = json.loads(resp.text)
builds = jsonreply['builds']

for build in builds:
  print str(build['timestamp'])[:-3]

