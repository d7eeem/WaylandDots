import sys
import os
from pathlib import Path
import os.path
import shutil

def f2f():
    os.chdir(sys.path[0])
    filecounter = 0
    tempDir = os.path.join(sys.path[0] + "\\temp")
    tempDirList = []
    mainFileList = []
# --- Preventing a mess.
    if os.path.exists(tempDir):
        print("Temp Dir already exists, cannot proceed")
        print("Exiting")
        sys.exit()
# --- Tree Log File
    os.system("tree /a /f > Logs.txt")
# ----- Dealing with Temp Directory
    print("____________")
    if not os.path.exists(tempDir):
        print("... Temp Dir Created ...")
        os.mkdir(tempDir)
    else:
        for fn in os.listdir(tempDir):
            tempDirList.append(fn)  
# ----- Dealing with Temp Directory
# --------------------------------------
# ----- File dealings
    for root, dirs, files in os.walk(cDir, topdown=True):
        # exclude = tempDir
        exclude = tempDir
        dirs[:] = [d for d in dirs if d not in exclude]
        # if root  == tempDir:
        #     print("ding")
        #     continue
# --------- for file in files
        for filename in files:
            filecounter += 1
# Separate base from extension
            base, extension = os.path.splitext(filename)
# old default File
            oldFile = os.path.join(root, filename)
            oldFileFolder = os.path.join(root) + "\\"
# New name for Temp Folder
            newFile = os.path.join(tempDir, base, filename)
            print("   -    -  Processing File:  -    -    ")
            print("oldFile =>", oldFile)
            if filename == os.path.basename(sys.argv[0]): #Skip Script File
                print("Script file detected. Skipping...")
                continue
# If folder basedir/base does not exist... You don't want to create it?
            if not os.path.exists(os.path.join(tempDir, base + "\\")):
                try:
                    print("not found ... ", os.path.join(tempDir, base))
                    os.mkdir(os.path.join(tempDir, base))
                    print("Folder Created ... ", tempDir, base)
                    shutil.move(oldFile, newFile)
                    print("Relocated ... ", newFile)
                    continue    # Next filename
                except:
                    print("Error in try")
# folder exists, file does not
            elif not os.path.exists(newFile):  
                try:
                    print("Relocated ... ", newFile)
                    shutil.move(oldFile, newFile)
                except:
                    print("Error in elif")
# folder exists, file exists as well
            else:  
                vNum = 2
                while True:
                    newFile = os.path.join(tempDir, base, base + " - Ver " + str(vNum) + extension)
                    if not os.path.exists(newFile):
                        print(f"File : {filename} \nIN {tempDir} ... already exists")
                        try:
                            print(f"Renaming : {filename}\n To : {newFile}")
                            shutil.move(oldFile, newFile)
                            print(f"Copied : {oldFile}\nTo : {newFile}")
                            break 
                        except:
                            print("Error in Else")
                    vNum += 1
    # Clean up old paths
    print("_____ CLEAN UP ____")
    for root, dirs, files in os.walk(cDir, topdown=True):
        exclude = tempDir
        dirs[:] = [d for d in dirs if d not in exclude]
        for dir in dirs:
            shutil.rmtree(dir)
            print("Removed : ", dir)
    # Moving files back to main directory
    tempDirList = os.listdir(tempDir)
    for tempFolderName in tempDirList:
        tempFolder = os.path.join(tempDir, tempFolderName)
        shutil.move(tempFolder, cDir)
    # Removing empty temp Dir
    shutil.rmtree(tempDir)
    print("Removed : ", tempDir)
# --- Tree Log File
    os.rename(r"Logs\Logs.txt", r"Logs\Before.txt")
    os.system(r"tree /a /f > .\Logs\After.txt")
    print("\n\n\t\tall done.")

def main():
    f2f()

if __name__ == "__main__":
    cDir = os.getcwd()
    main()
