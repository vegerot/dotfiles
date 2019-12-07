#!/usr/bin/env python3
import sys
def colats(num):
    if num==1:
        return num
    if num%2==0:
        print(num)
        colats(num/2)
    else:
        print(num)
        colats(3*num+1)

def colatsIter(num,cnt,factor=3):
    for i in range(cnt):
        if num%2==0:
            num/=2
        else:
            num=factor*num+1
        print(num);

def main():
    if len(sys.argv)==4:
        num,factor,cnt=[int(i) for i in sys.argv[1:]]
        colatsIter(num,cnt,factor)
    else:
        num,cnt=[int(i) for i in sys.argv[1:]]
        colatsIter(num,cnt)

main()
