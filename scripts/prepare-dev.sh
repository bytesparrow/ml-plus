#!/bin/bash

scriptpath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/"
  
# Define the file_composer_local path
file_composer_local=$scriptpath"../composer.local-packages.json"

# Use sed to extract all package names from the file_composer_local
sed_packages=$(sed -n '/^\s*"url":/ s/.*"\(local_dev_packages\/\)\(.*\)".*/\2/p' "$file_composer_local")

# Convert sed_packages to an array
mapfile -t dev_packages <<< "$sed_packages"

echo "CLONING DEV-PACKAGES TO local_dev_packages"
sleep 5

for packg_name in ${dev_packages[@]}; do
    echo ${packg_name}
    packagauthor=${packg_name%"/"*}
    dirpath="local_dev_packages/"${packagauthor}
    gitlink="https://github.com/"${packg_name}".git"
    cd $scriptpath".."
    mkdir -p $dirpath
    cd $dirpath
    git clone $gitlink

done
 
cd $scriptpath
echo ""
echo ""
echo ""
echo "CLONING finished"
echo 'in composer.json add the following line in the [extra > merge-plugin] section'
echo ""
echo '"include": ["composer.local-packages.json"],'
echo ""
echo ""