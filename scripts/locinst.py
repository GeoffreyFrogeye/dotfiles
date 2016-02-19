#!/usr/bin/env python3

import json
import urllib.request
import subprocess
import os
import sys
import re

LOCINST_DIR=os.environ['HOME']+'/.locinst'
LOCINST_DB=os.environ['HOME']+'/.config/locinst'
LOCINST_TMP='/tmp/locinst'

DEBIAN_MIRROR = 'http://debian.polytech-lille.fr/debian/'

def globallyInstalled(name):
    try:
        a = subprocess.check_output(['apt-cache', 'policy', name]).decode('utf8').strip().lower()
        return 'installé\xa0: (aucun)' not in [b.strip() for b in a.split('\n')]
    except FileNotFoundError:
        return False

def locallyInstalled(name):
    return False

def debian_install(name):
    def findPackage(name):
        raw = urllib.request.urlopen('http://sources.debian.net/api/search/' + name + '/')
        data = json.loads(raw.read().decode('utf8'))
        results = data['results']
        if results['exact']:
            return True
        else:
            print("Package " + name + " does not exist" + (", however you might want to try one of the following: " + ", ".join([pkg['name'] for pkg in results['other']]) if results['other'] else "") + ".")
            return False
        
    def findVersion(name):
        raw = urllib.request.urlopen('http://sources.debian.net/api/src/' + name + '/')
        data = json.loads(raw.read().decode('utf8'))

        def findByCodename(codename):
            goodVersions = [version['version'] for version in data['versions'] if codename in version['suites']]
            return goodVersions[0] if len(goodVersions) else False

        try:
            codename = subprocess.check_output(['lsb_release', '--codename', '--short']).decode('utf8').strip().lower()
            choice = findByCodename(codename)
            if choice:
                return choice
        except FileNotFoundError:
            pass

        return findByCodename('jessie')

    def parseInfos(control):
        paragraph = {}
        key = ''

        for line in control.strip().split('\n'):
            if re.match('\s', line[0]):
                try:
                    paragraph[key] += '\n' + line.strip()
                except KeyError:
                    pass
            elif re.match('^[\w-]+\:', line):
                key = line.split(':')[0].lower()
                paragraph[key] = line[len(key)+1:].strip()

        return paragraph

    def getArch():
        arch = subprocess.check_output(['uname', '--machine']).decode('utf8').strip().lower()
        if arch == 'x86_64':
            arch = 'amd64'
        return arch


    def download(name, version):
        arch = getArch()
        filename =  name + '_' + version + '_' + arch

        print("Downloading " + filename + "...")
        url = DEBIAN_MIRROR + 'pool/main/' + (name[0] if name[0:3] != 'lib' else name[0:4]) + '/' + name + '/' + filename + '.deb'
        debfile = LOCINST_TMP + '/' + filename + '.deb'
        urllib.request.urlretrieve(url, debfile)

        extractdir = LOCINST_TMP + '/' + filename
        try:
            os.mkdir(extractdir)
        except FileExistsError:
            pass
        subprocess.check_call(['ar', 'x', debfile], cwd=extractdir)
        subprocess.check_call(['rm', '-rf', debfile], stdout=subprocess.DEVNULL) 

        controltar = [a for a in os.listdir(extractdir) if a.split('.')[:2] == ['control', 'tar']][0]
        subprocess.check_call(['tar', 'xf', extractdir + '/' + controltar], cwd=extractdir)
        with open(extractdir + '/control') as controlfile:
            control = controlfile.read()

        finaldir = LOCINST_TMP + '/' + name
        try:
            os.mkdir(finaldir)
        except FileExistsError:
            pass
        datatar = [a for a in os.listdir(extractdir) if a.split('.')[:2] == ['data', 'tar']][0]
        subprocess.check_call(['tar', 'xf', extractdir + '/' + datatar], cwd=finaldir)

        subprocess.check_call(['rm', '-rf', extractdir]) 
        return {
                'final': finaldir,
                'control': control
        }


    if not findPackage(name):
        return 4

    if globallyInstalled(name):
        return 5

    print("Installing " + name + "...")
    version = findVersion(name)

    if not version:
        return 6

    d = download(name, version)
    finaldir, control = d['final'], d['control']

    infos = parseInfos(control)

    if 'depends' in infos:
        for dep in infos['depends'].split(', '):
            dep = dep.strip().split(' ')[0]
            if not globallyInstalled(dep):
                # print("Installing " + dep + " as a dependency")
                # debian_install(dep)

                # TODO For compatibility until locinst.sh is rewritten
                try:
                    subprocess.check_call([os.environ['HOME'] + '/.scripts/locinst.sh', 'debian', dep])
                except subprocess.CalledProcessError:
                    pass
            
    if 'recommends' in infos:
        for rec in infos['recommends'].split(','):
            print(name + " suggests you to install: " + rec.strip())

    return 0

# TODO For compatibility until locinst.sh is rewritten
exit(debian_install(sys.argv[1]))
