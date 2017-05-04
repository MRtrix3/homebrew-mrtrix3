#!/usr/bin/env python
import os, sys
import re, requests

def parse_remote():
    # same format as git describe --tags
    # uses api to avoid cloning
    m = re.compile("(\d+.\d+)")
    r = requests.get('https://api.github.com/repos/MRtrix3/mrtrix3/tags', json={"key": "value"}).json()
    try:
        remote_tags = [(x['name'], x['commit']['sha']) for x in r if m.search(x['name'])]
    except:
        print r
        sys.exit(1)
    tag = remote_tags[0][0]
    tag_sha = remote_tags[0][1]
    master_sha = requests.get('https://api.github.com/repos/MRtrix3/mrtrix3/commits/master', json={"key": "value"}).json()['sha']

    r = requests.get('https://api.github.com/repos/MRtrix3/mrtrix3/compare/'+tag_sha+'...'+master_sha, json={"key": "value"}).json()
    try:
        total_commits = r['total_commits']
    except:
        print r
        sys.exit(1)
    describe = "%s-%s-g%s" % (tag, total_commits, master_sha[:8])
    return describe

if __name__ == '__main__':
    import subprocess, tempfile, shutil

    tempdir = tempfile.mkdtemp()
    try:
        print (tempdir)
        os.chdir(tempdir)
        subprocess.call("git clone https://github.com/MRtrix3/homebrew-mrtrix3.git", shell = True)
        os.chdir(tempdir+"/homebrew-mrtrix3")

        with open ('mrtrix3.rb', 'r') as fin:
            formula = fin.readlines()
        current_line = None
        for iline, line in enumerate(formula):
            if line.lstrip().startswith('version'):
                current_line = line
                break

        if current_line is None:
            raise Exception ("version parsing failed")
        current = current_line.split()[1].replace("'", "")
        print ("formula: " + current)

        remote = parse_remote()
        print ("remote: " + remote)

        if remote != current:
            formula[iline] = current_line.replace(current, remote)
            formula[iline + 1] = 'revision 0'
            with open ('mrtrix3.rb', 'w') as fout:
                fout.writelines(formula)
            subprocess.call('git add mrtrix3.rb', shell = True)
            subprocess.call('git commit -m "automatic formula update to ' + remote + '"', shell = True)
            subprocess.call('git push', shell = True)
    finally:
        shutil.rmtree(tempdir, ignore_errors=False, onerror=None)




