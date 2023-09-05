import os
import subprocess
import sys
import shutil
import datetime

# timeway_packer.py
# Used for when exporting a release of Timeway for uploading on Github,
# prints out update json info.

# Copied from another project, have some boilerplate code here
class color:

    HEADER    = '\033[95m'
    YELLOW    = '\033[93m'
    LRED      = '\033[91m'
    BLUE      = '\033[34m'
    PURPLE    = '\033[35m'
    CYAN      = '\033[36m'
    GREEN     = '\033[32m'
    GOLD      = '\033[33m'
    RED       = '\033[31m'
    GREY      = '\033[90m'
    BLACK     = '\033[30m'
    NONE      = '\033[0m'
    WHITE     = '\033[29m'
    BOLD      = '\033[1m'
    UNDERLINE = '\033[4m'

    HRED      = '\033[41m'
    HGREEN    = '\033[42m'
    HYELLOW   = '\033[43m'
    HBLUE     = '\033[44m'
    HPURPLE   = '\033[45m'
    HCYAN     = '\033[46m'
    HWHITE    = '\033[47m'


def command(c):
    x = subprocess.check_output([c], shell=True)
    s = ""
    for i in x:
        s += chr(i)
    return s

# Check if the folder we're in is "Timeway"
# get our directory we're in
dir = os.getcwd()
# split it by the "/" character
dir = dir.split("/")
# get the last element of the list
dir = dir[len(dir)-1]
# check if it's "Timeway"
if (dir != "Timeway"):
    print(color.RED+"Error: Timeway directory not found."+color.NONE)
    exit(1)

# Cool title thing
print(color.PURPLE)
packer_color = color.BLUE
print(""" _____ _                           {c}           ____            _ {n}
|_   _(_)_ __ ___   _____      ____ _ _   _ {c} |  _ \ __ _  ___| | _____ _ __{n}
  | | | | '_ ` _ \ / _ \ \ /\ / / _` | | | |{c} | |_) / _` |/ __| |/ / _ \ '__|{n}
  | | | | | | | | |  __/\ V  V / (_| | |_| |{c} |  __/ (_| | (__|   <  __/ |{n}
  |_| |_|_| |_| |_|\___| \_/\_/ \__,_|\__, |{c} |_|   \__,_|\___|_|\_\___|_|{n}
                                      |___/""".format(c=packer_color, n=color.PURPLE))
print(color.NONE)

skipPackaging = False
output_to_file = False
# Get all the arguments
for arg in sys.argv:
    if (arg == "-s"):
        skipPackaging = True
    elif (arg == "-h"):
        print(color.GOLD+"Usage: python3 timeway_packer.py [-s][-h][-o]"+color.NONE)
        print(color.GREY+"-s: Skip packaging the release, just print out the update info json."+color.NONE)
        print(color.GREY+"-h: Print this help message."+color.NONE)
        print(color.GREY+"-o: Output the update info json to a file."+color.NONE)
        exit(0)
    elif (arg == "-o"):
        # Output the update info json to a file
        output_to_file = True
    


# prompt for version
version_original = input("Enter version: ")

# Replace '-' with '_'
version = version_original.replace("-", "_")
version = version.replace(".", "_")

actionsComplete = False

# Check for folder application.windows64 folder
new_name = "timeway_windows_"+version
if (os.path.isdir("application.windows64")):
    # rename to timeway_windows_(version)
    os.rename("application.windows64", new_name)

# If a folder with files called timeway_windows exists from a previous packaging, delete it.
if (os.path.isdir("timeway_windows")):
    shutil.rmtree("timeway_windows")

windows_executable_location = "null"
windows_stability = 0
windows_download_size = 1  # Needs to be at least 1kb
if (os.path.isdir("timeway_windows_"+version)):
    actionsComplete = True
    windows_stability = 5
    windows_executable_location = "timeway_windows_"+version+"/Timeway.exe"
    # move all .dll files in timeway_windows_(version)/lib (apart from dsj.dll) to windows64
    # check if lib dir exists
    success = True
    if (not os.path.isdir(new_name+"/lib")):
        print(color.RED+"Error: lib directory not found."+color.NONE)
        success = False
    else:
        # move all .dll files in lib to windows64
        if (not os.path.isdir(new_name+"/lib/windows64")):
            os.mkdir(new_name+"/lib/windows64")
        for file in os.listdir(new_name+"/lib"):
            if (file.endswith(".dll") and file != "dsj.dll"):
                os.rename(new_name+"/lib/"+file, new_name+"/lib/windows64/"+file)
                print("Moved "+file+" to windows64 folder.")

        if (os.path.isdir(new_name+"/lib/gstreamer-1.0")):
            os.rename(new_name+"/lib/gstreamer-1.0", new_name+"/lib/windows64/gstreamer-1.0")
            print("Moved gstreamer folder to windows64 folder.")

        # If the lib folder does not have dsj.dll, copy it from the code folder to the lib folder
        if (not os.path.isfile(new_name+"/lib/dsj.dll")):
            if (os.path.isfile("code/dsj.dll")):
                # copy the dsj.dll file to the lib folder
                shutil.copy("code/dsj.dll", new_name+"/lib/dsj.dll")
                print("Copied dsj.dll to lib folder.")
            else:
                print(color.RED+"Error: code/dsj.dll doesn't exist!"+color.NONE)
                print(color.GREY+"dsj is part of the library for camera functionality. Exporting doesn't include it by default. Please ensure it's in a folder called \"code\" in the Timeway dir."+color.NONE)
                success = False

        if (success):
            print(color.GREEN+"Moved dll files to windows64 folder."+color.NONE)
    
    # Do a bit of housecleaning of our package and delete the cache folder keybindings.json and config.json
    if (os.path.isdir(new_name+"/data/cache")):
        shutil.rmtree(new_name+"/data/cache")
        print("Removed cache folder.")
    if (os.path.isfile(new_name+"/data/keybindings.json")):
        os.remove(new_name+"/data/keybindings.json")
        print("Removed keybindings.json.")
    if (os.path.isfile(new_name+"/data/config.json")):
        os.remove(new_name+"/data/config.json")
        print("Removed config.json.")
    # Also recursively search and remove any files beginning with .pixelrealm from the folders
    files_to_remove = []
    for root, dirs, files in os.walk(new_name):
        for file in files:
            if (file.startswith(".pixelrealm")):
                files_to_remove.append(os.path.join(root, file))
    
    if (len(files_to_remove) > 0):
        print(color.GOLD+"Found "+str(len(files_to_remove))+" .pixelrealm files. Remove them? Y/N"+color.NONE)
        if (input().lower() == "y"):
            for file in files_to_remove:
                os.remove(file)
                print("Removed "+file)
    

    # Finally, compress the folder to a zip file
    if (not skipPackaging):
        zip = True
        if (not success):
            print(color.GOLD+"Some things went wrong with preparing the package. Continue with zipping? Y/N")
            if (input().lower() != "Y"):
                print(color.GOLD+"Skipping"+color.NONE)
                zip = False

        if (zip):
            print(color.WHITE+"Zipping (patience, this may take some time)..."+color.NONE)
            # We don't want loose items in the zip folder
            # so put it all in another folder of the same name
            zip_source = "timeway_windows"+"/"+new_name
            if (not os.path.isdir("timeway_windows")): 
                os.mkdir("timeway_windows")
            os.rename(new_name, zip_source)

            shutil.make_archive(new_name, 'zip', "timeway_windows")
            # Make bell sound in terminal to indicate finished zipping
            print("\a")
            print(color.GREEN+"Done."+color.NONE)
    
    # Get the size of the zip file
    if (os.path.isfile(new_name+".zip")):
        windows_download_size = os.path.getsize(new_name+".zip")
        windows_download_size = windows_download_size/1000
        windows_download_size = int(windows_download_size)
        print(color.WHITE+"Download size: "+str(windows_download_size)+"kb"+color.NONE)
            
    

linux_executable_location = "null"
linux_stability = 0
linux_download_size = 1  # Needs to be at least 1kb
if (os.path.isdir("application.linux64")):
    print(color.GOLD+"Linux not yet supported."+color.NONE)

macos_executable_location = "null"
macos_stability = 0
macos_download_size = 1  # Needs to be at least 1kb
if (os.path.isdir("application.macosx64")):
    print(color.GOLD+"MacOS not yet supported."+color.NONE)
    

TIMEWAY_NAME = "Timeway"
COMPATIBLE_VERSIONS = ["0.0.4-d01", "0.0.4", "0.0.3", "0.0.2", "0.0.1"]
windows_stability = 5
# Print out update info json
info = """
{{
    "info-version": "{info_version}",
    "timeway-name": "{timeway_name}",
    "update-name": "{update_name}",
    "version": "{update_version}",
    "type": "update",
    "release-date": "{date}",
    "compatible-versions": ["{compatible_versions}"],
    "windows-stability": {windows_stability},
    "linux-stability": {linux_stability},
    "macos-stability": {macos_stability},
    "windows-download-size": {windows_download_size},
    "linux-download-size": {linux_download_size},
    "macos-download-size": {macos_download_size},
    "windows-executable-location": "{windows_executable_location}",
    "linux-executable-location": "{linux_executable_location}",
    "macos-executable-location": "{macos_executable_location}",
    "update-if-incompatible": false,
    "incompatible-warning": "[default]",
    "priority": 1, 
    "force-update": false,
    "windows-download": "INSERT HERE",
    "linux-download": "INSERT HERE",
    "macos-download": "INSERT HERE",
    "install-location": "[default]",
    "move-files": [
        {{
            "from": "data/cache/*",
            "to": "data/cache/*"
        }},
        {{
            "from": "data/config.json",
            "to": "data/config.json"
        }},
        {{
            "from": "data/keybindings.json",
            "to": "data/keybindings.json"
        }}
    ],
    "old-version-action": "backup",
    "run-after-update": true,
    "error-handler": "[none]",
    "display-header": "{display_header}",
    "display-message": "{display_message}",
    "display-footer": "{display_footer}",
    "additional-message": "[none]",
    "warnings": "[none]",
    "patch-notes": "{patch_notes}"
}}
""".format(
    info_version="0.1",
    timeway_name=TIMEWAY_NAME,
    update_name=TIMEWAY_NAME+" "+version_original,
    update_version=version_original,
    date=datetime.datetime.now().strftime("%d/%m/%Y"),
    compatible_versions="\", \"".join(COMPATIBLE_VERSIONS),
    windows_stability=windows_stability,
    linux_stability=linux_stability,
    macos_stability=macos_stability,
    windows_download_size=windows_download_size,
    linux_download_size=linux_download_size,
    macos_download_size=macos_download_size,
    windows_executable_location=windows_executable_location,
    linux_executable_location=linux_executable_location,
    macos_executable_location=macos_executable_location,
    display_header="[default]",
    display_message="[default]",
    display_footer="[default]",
    patch_notes=""
)

if (not actionsComplete):
    print(color.RED+"There isn't any exported applications to package up..."+color.NONE)
else:
    print(info)
    print(color.GOLD+"\nRemember to fill in the blank \"INSERT HERE\" spaces!"+color.NONE)

if (output_to_file):
    f = open("timeway_update.json", "w")
    f.write(info)
    f.close()


# w = open(env("MYDATA_TEMP")+"/example_file.txt", "w")
# w.write("Never gonna give you up, never gonna let you down.")
# w.close()


# os.system("xdg-open .")
# print(command("ls"))



