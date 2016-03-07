#!/usr/bin/python

from urllib2 import urlopen
from urllib import urlretrieve
import json
import os
import sys
from datetime import datetime
import tarfile
import subprocess

file = urlopen('https://atlas.hashicorp.com/api/v1/box/ubuntu/trusty64')
box_info = json.loads(file.read())
provider_info = None

for provider in box_info['current_version']['providers']:
	if provider['name'] == 'virtualbox':
		provider_info = provider
		break

if provider_info is None:
	print 'Box for provider not found: virtualbox'
	sys.exit(0)

up_to_date = True

if os.path.isfile('./latest.txt'):
	file = open('./latest.txt', 'r')
	local_updated_at = datetime.strptime(file.read().strip(), '%Y-%m-%dT%H:%M:%S.%fZ')
	remote_updated_at = datetime.strptime(provider_info['updated_at'], '%Y-%m-%dT%H:%M:%S.%fZ')
	if remote_updated_at > local_updated_at:
		up_to_date = False
else:
	up_to_date = False

if up_to_date:
	print 'Box is up to date'
	sys.exit(0)

urlretrieve(provider_info['download_url'], 'latest.box')

box = tarfile.open('latest.box')
files = box.getmembers()

for file in files:
	if not file.name in ['box.ovf', 'box-disk1.vmdk']:
		files.remove(file)

box.extractall('./source', files)

packer_exit_code = subprocess.call(['packer', 'build', 'template.json'])

if packer_exit_code:
	print 'Build failed'
	sys.exit(0)

print 'Build complete'



file = open('./latest.txt', 'w')
file.write(provider_info['updated_at'])
