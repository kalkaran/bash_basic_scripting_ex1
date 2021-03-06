#!/usr/bin/env bash
# Script to automate installation of packages - Ex.1
#     .--.
#    |o_o |
#    |:_/ |
#   //   \ \
#  (|     | )
# /'\_   _/`\
# \___)=(___/
# Valdemar er en pingvin
# https://nmap.org/dist/nmap-7.91-1.x86_64.rpm

# 1.Ask for the package to be downloaded [DONE]
# 2.Then ask if it want to install from source code or with dpkg/rpm [DONE]
# 3.It then asks for the link to download the packages [DONE]
# 4.It checks/changes for the permission of the folder /usr/local/src such that everybody can download and use packages downloaded there [DONE]
# 5.It then downloads the package in /usr/local/src [DONE]
# 6.It should then install the package depending on the choice of package downloaded.[DONE]
# 7.Report if the installation was successful [DONE]
# 8.If not then what was the reason (maybe there were some dependencies that were missing- prompt to download and install those packages before downloaded the initial package that was to be installed) [DONE]

# 9.[optional][extra credits] find the package in apt-cache and prompt to install them and then reinstall the initial package to be installed
# 10.[optional][extra credits]  make it possible to run the script without sudo. Hint Look into sudoers file use visudo

script_name=$0

# On the first error encountered, stop!
#set -e

# A function that shows how to use the program
show_usage() {
  echo "Usage: $script_name"
  echo "or"
  echo "Usage: $scipt_name -a --link=<link>"
  exit
}

# Check that arguments contain the right stuff
a_flag=''

while test $# -gt 0; do
  case "$1" in
  -h | --help)
    echo "Usage: $script_name"
    echo "or"
    echo "Usage: $script_name -a|--automatic_install -l|--link=<link>"
    echo " "
    echo "options:"
    echo "-h, --help                show brief help"
    echo "-a, --automatic_install   automatically select settings for install"
    echo "-l, --link                specify a link for package (required for automatic install)"
    exit 0
    ;;
  -a | --automatic_install)
    a_flag='true'
    ;;
  -l | --link)
    shift
    if test $# -gt 0; then
      export LINK_INPUT=$1
    else
      echo "no link specified"
      exit 1
    fi
    shift
    ;;
  *)
    show_usage
    break
    ;;
  esac
done

# return Linux version and distribution
if [ -f /etc/centos-release ]; then
  Operating_System="CentOs"
  full=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)
  Version=${full:0:1} # return 6 or 7
elif [ -f /etc/lsb-release ]; then
  Operating_System=$(grep DISTRIB_ID /etc/lsb-release | sed 's/^.*=//')
  Version=$(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//')
else
  Operating_System=$(uname -s)
  Version=$(uname -r)
fi
arch=$(uname -m)

installation_target="/usr/local/src"

echo "Operating System : $Operating_System  $Version  $arch"
echo '     .--.'
echo '    |o_o | '
echo '    |:_/ | '
echo '   //   \ \  '
echo '  (|     | )  '
echo " /'\_   _/'\  "
echo ' \___)=(___/  '
echo 'Valdemar er en Ping - vin'

#Menu for choosing package
menu() {
  read -e -p "Type in the package you wish to download: " PACKAGE_FOR_INSTALL
  echo "#############################################"
  echo "How do you wish to install ${PACKAGE_FOR_INSTALL}"
  read -e -p "(1):Install from source, (2): Install via dpkg or rpm, (q):Quit installer? " option
  case $option in
  "1")
    echo "Selection was 1. Install from source"
    ;;
  "2")
    echo "Selection was 2. Install via dpkg or rpm"
    ;;
  [Qq]*)
    echo "Goodbye !"
    exit
    ;;
  *) echo "invalid option $option" ;;
  esac
  read -e -p "Please enter link to package: " LINK_TO_PACKAGE
  echo "Url for package: $LINK_TO_PACKAGE"
}

check_permissions() {
  folder_to_check=$1
  echo "Checking Folder Permissions for $folder_to_check"
  permissions=$(stat -L -c "%a" $folder_to_check)
  #permissions=XXX
  first_number="${permissions:0:1}"
  second_number="${permissions:1:2}"
  third_number="${permissions:2:3}"

  if [[ $third_number -eq 7 ]] || [[ $third_number -eq 6 ]]; then
    echo "You have the correct permissions for $folder_to_check"
  else
    echo "You do not have write permissions for $folder_to_check"
    echo "Changing permissions now"
    chmod -R 777 ${installation_target}
  fi
}

download_package() {
  echo "Downloading Package"
  path_to_package="${installation_target}/"
  #check if wget installed?
  wget "${LINK_TO_PACKAGE}" -P "${path_to_package}"
}

check_file_type() {
  #needs to check file type
  echo "Checking file type"
  echo "File types supported:"
  echo "deb"
  echo "rpm"
  echo "zip"
  echo "tar.bz2"
  echo "tar.gz"
  echo "tar.xz"
  echo "tar"
  echo "bz2"
  echo "tgz"

  # URL FILE FORMAT : https://nmap.org/dist/nmap-7.91-1.x86_64.rpm
  #save link as an array split by /
  IFS='/' read -ra my_array <<<"$LINK_TO_PACKAGE"
  # get last element of array unless the link ends on /
  #echo "$LINK_TO_PACKAGE"
  if [[ ${my_array[-1]} != "" ]]; then
    filename=${my_array[-1]}
  else
    filename=${my_array[-2]}
  fi
  echo $filename
  path_to_package_file="${installation_target}/${filename}"
  #example: nmap-7   91-1    x86_64   rpm
  IFS='.' read -ra my_ext <<<"$filename"
  #echo "$filename"
  #check if empty ext
  if [[ ${my_ext[-1]} != "" ]]; then
    ext1=${my_ext[-1]}
    ext2=${my_ext[-2]}
    case $ext1 in
    "bz2")
      echo "bz2 found checking for tar"
      if [[ $ext2 == "tar" ]]; then
        ext="tar.bz2"
      else
        ext="bz2"
      fi
      ;;
    "gz")
      echo "gz found checking for tar"
      if [[ $ext2 == "tar" ]]; then
        ext="tar.gz"
      else
        ext="gz"
      fi
      ;;
    "xz")
      echo "xz found checking for tar"
      if [[ $ext2 == "tar" ]]; then
        ext="tar.xz"
      else
        ext="xz"
      fi
      ;;
    "deb")
      ext=$ext1
      echo "$ext1 file found"
      ;;
    "tgz")
      ext=$ext1
      echo "$ext1 file found"
      ;;
    "rpm")
      ext=$ext1
      echo "$ext1 file found"
      ;;
    "zip")
      ext=$ext1
      echo "$ext1 file found"
      ;;
    *)
      echo "File format '$ext1' not recognised"
      ext="FAILED"
      ;;
    esac
  else
    ext="FAILED"
    exit
  fi
}

install_package() {
  echo "Installing Package"
  check_file_type
  if [[ $ext != "FAILED" ]]; then
    case $option in
    "1")
      echo "Installing from source"
      echo "for Operating System : $Operating_System  $Version  $arch"
      if [[ $ext == "deb" ]] || [[ $ext == "rpm" ]]; then
        echo "This is not an archive containing source code - will now redirect to dpkg or rpm installation"
      else
        echo "Preparing to install from source $path_to_package_file"
      fi
      ;;
    "2")
      echo "Installing via rpm/dkpg"
      echo "Operating System : $Operating_System  $Version  $arch"
      if [[ $ext != "deb" ]] && [[ $ext != "rpm" ]]; then
        echo "This is not an rpm or deb file - attempting to instal from source code archive"
      else
        echo "Preparing to install from $path_to_package_file"
      fi
      ;;
    esac

    if [[ $Operating_System == "CentOS" ]]; then
      echo "Not implemented yet"
    elif [[ $Operating_System == "Ubuntu" ]]; then
      case $ext in
      "deb")
        echo "installing ${PACKAGE_FOR_INSTALL}"
        dpkg -i $path_to_package_file
        if [[ ! $? -eq 0 ]]; then
          echo "installing failed"
        fi
        ;;
      "rpm")
        echo "You are trying to install a redhat package on UBUNTU you will be forced to install alien now"
        sudo apt-get install -yqq alien
        sudo alien -i $path_to_package_file
        if [[ ! $? -eq 0 ]]; then
          echo "installing failed"
        fi
        ;;
      *)
        sudo apt-get install -yqq build-essential
        sudo apt-get install -yqq checkinstall

        cd $installation_target

        # Check if folder is there or create it with the right permission
        if [[ ! -d "$installation_target/source_code" ]]; then
          mkdir "$installation_target/source_code"
          chmod -R 777 "$installation_target/source_code"
        fi

        tar -xf $path_to_package_file -C "$installation_target/source_code" &&
          foldername=$(ls "$installation_target/source_code" | grep "${my_ext[0]}")
        cd "$installation_target/source_code/$foldername"

        if [[ ./configure ]]; then
          echo "configuration successful"
          if [[ make ]]; then
            echo "make successful"
          else
            echo "make failed"
          fi
        else
          echo "configuration failed"
        fi
        error_status=$(sudo checkinstall 2>&1 1>/dev/null)
        check_installation_status
        ;;
      esac
    else
      echo "¯\_(ツ)_/¯"
    fi
  else
    echo "¯\_(ツ)_/¯"
  fi
}

check_installation_status() {
  echo "Status for installation"
  if [[ $error_status != "" ]]; then
    echo "the following error was detected"
    echo "$error_status"
    exit
  fi
}


install_dependencies() {
  apt-cache showpkg $1
  echo "You need the $1 package to install ${PACKAGE_FOR_INSTALL}"
  read -p "Do you want to install this package before reinstalling ${PACKAGE_FOR_INSTALL}" -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
  apt-get install -f
  install_package
}

delta_force() {
  apt install sl
  sl -F
}

main() {
  if [ ${a_flag} == 'true' ]; then
    PACKAGE_FOR_INSTALL="Automatic_Install"
    option='x'
    LINK_TO_PACKAGE=${LINK_INPUT}
  else
    menu
  fi
  check_permissions $installation_target
  download_package
  check_file_type
  install_package

  #delta_force
}

# https://nmap.org/dist/nmap-7.91-1.x86_64.rpm
# http://archive.ubuntu.com/ubuntu/pool/main/s/samba/samba_4.11.6+dfsg-0ubuntu1_amd64.deb
main
