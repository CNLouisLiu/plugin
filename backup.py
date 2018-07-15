import os
import os.path
import shutil
import time

source_dir = r"C:\JX3\Game\JX3\bin\zhcn_hd\interface\LR_Plugin"
target_dir = r"j:\剑网3插件制作\提交提交提交提交" + "\\" + time.strftime("%Y%m%d") + "\\LR_Plugin"
ignor = shutil.ignore_patterns("*.py", "*.pyc", "*.key", "*.dat", "*.bak", "@DATA2", "@DATA", ".idea", "__pycache__", "*副本*", "Usrdata", ".git", ".gitignore")

if os.path.exists(target_dir):
    shutil.rmtree(target_dir)

shutil.copytree(source_dir, target_dir, ignore=ignor)

zip_command = "7z a " + r"j:\剑网3插件制作\提交提交提交提交" + "\\" + time.strftime("%Y%m%d") + "\\LR_Plugin.zip " + r"j:\剑网3插件制作\提交提交提交提交" + "\\" + time.strftime("%Y%m%d") + "\\LR_Plugin"
os.system(zip_command)
shutil.rmtree(r"j:\剑网3插件制作\提交提交提交提交" + "\\" + time.strftime("%Y%m%d") + "\\LR_Plugin")

