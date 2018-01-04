# -*-coding:utf-8 -*-
#test

import os.path
import codecs
import sys
from langconv import *

print(sys.version)
print(sys.version_info)

# 转换繁体到简体
def T2S(line):
    line = Converter('zh-hans').convert(line)
    line.encode('utf-8')
    return line

# 转换简体到繁体
def S2T(line):
    line = Converter('zh-hant').convert(line)
    line.encode('utf-8')
    return line

def file_c2t(path, filename):
    file = open(path + "\\" +filename, 'rt', encoding="ansi")
    line = file.read()
    line2 = S2T(line)
    file2 = open(path + '\\zhtw.jx3dat', 'wt', encoding="utf-8")
    file2.write(line2)
    file.close()
    file2.close()

rootdir = r'C:\JX3HD\bin\zhcn_hd\interface\LR_Plugin'

for parent, dirnames, filenames in os.walk(rootdir):
    for filename in filenames:
        if filename == "zhcn.jx3dat":
            file_c2t(parent, filename)


#print("翻译完成")