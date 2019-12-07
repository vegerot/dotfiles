#!/usr/bin/env python3
import subprocess
import re
import sys
import time
import argparse


def main():
    #sys.stdin.reconfigure(encoding='utf-8', errors=None)
    parser = argparse.ArgumentParser(description='Get progress on your Time\
                                     Machine backups')
    parser.add_argument("--ol", default=0, help="specifies level  relative to\
                        /")
    parser.add_argument("--il", default=0, help='specifies level relative to\
                        end')
    args = parser.parse_args()
    ol = int(args.ol)
    il = int(args.il)
    log = '14:29:52.776585    HFS_update               (__MN_c_m)  pdb/Max’s MacBook Pro/2019-09-10-115720/Macintosh HD/Users/maxcoplan/Library/Application Support/AddressBook/Sources/0F026D67-98B6-48C5-B5C6-E98F27188E09/Images    0.000003   backupd.1116490'
    k = 0
    reg = re.compile(r'HFS_update\s+.*?(?P<path>/.*?)\s+0\.')
    try:
        buff = ''  # .encode('utf-8', 'ignore')
        prev = ''
        while True:
            try:
                buff += sys.stdin.read(1)  # .strip().encode('utf-8', 'ignore')
                if buff.endswith('\n'):
                    try:
                        res = reg.search(buff).group('path').split('/')
                        if ol == 0:
                            txt = '/'.join(res[0:len(res)-il])
                        else:
                            txt = '/'.join(res[0:ol])
                        if not txt == prev:
                            prev = txt
                            print(txt+'\n')
                    except AttributeError:
                        #print('IGNORE', buff[:-1])
                        pass
                    buff = ''  # .encode('utf-8', 'ignore')
                    k = k + 1
            except UnicodeDecodeError:
                sys.stdout.flush()
                print(buff)
    except KeyboardInterrupt:
        sys.stdout.flush()


if __name__ == "__main__":
    main()
