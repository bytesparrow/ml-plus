#!/bin/bash

scriptpath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/"



pluginpath=$1
if [[ ! $pluginpath ]];
then
    echo "Usage: create-new-plugin-version.sh PATH_TO_SOME_PLUGIN"
    exit 2
fi

composerfile="$pluginpath/composer.json"
pluginfile="$pluginpath/version.php"


composerversionline=`grep '"version":' $composerfile`
pluginversionline=`grep '$plugin->version' $pluginfile`

#composer +1
composerversionclean=`echo $composerversionline |  grep -Po '\"version\"\s*:\s*"\K.*?(?=")'`
composerversionpluseins=`echo $composerversionclean | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{$NF=sprintf("%0*d", length($NF), ($NF+1)); print}'`


#plugin +1
pluginversionclean=`echo $pluginversionline |  grep -Po '[$]plugin->version\s*=\s*\K.*?(?=;)'`
pluginversionpluseins=$((pluginversionclean+1))


echo ""
echo "Will now update composer-version from: $composerversionclean to $composerversionpluseins"
echo "and plugin-version from: $pluginversionclean to $pluginversionpluseins"

echo ""
echo "Are those settings correct?"
read  -n 1 -p "Hit enter for yes. STRG+C to cancel." dummyinput



composerversionpluseinsline=${composerversionline/"$composerversionclean"/"$composerversionpluseins"}
pluginversionpluseinsline=${pluginversionline/"$pluginversionclean"/"$pluginversionpluseins"}

sed -i "s/$composerversionline/$composerversionpluseinsline/g" $composerfile
sed -i "s/$pluginversionline/$pluginversionpluseinsline/g" $pluginfile

cd $pluginpath

read  -n 1 -p "Will now show git diff. Exit diff with 'q'. STRG+C to cancel." dummyinput
git diff .

echo ""
echo "Was the result as expected?"
read  -n 1 -p "Hit enter for yes. STRG+C to cancel." dummyinput

git add composer.json version.php

echo ""
echo "Please review 'git status' now."
read  -n 1 -p "Hit enter to continue. STRG+C to cancel." dummyinput

git status . 
echo ""
echo "Ready to commit and push your changes?"
read   -p "Enter your commitmessage and hit enter to continue. STRG+C to cancel:" commitmsg

if [ -z "$commitmsg" ]
then
      read  -p "Enter your commitmessage and hit enter to continue. STRG+C to cancel: " commitmsg
fi

echo "Your commitmsg is: $commitmsg"
exit


git commit -m $commitmsg

git push

git tag $composerversionpluseins

git push origin composerversionpluseins

echo ""
echo "Done."
exit


#################################
## TESTSTUFF
#'''''''''''''''''''''''''''''''''
# Accepts a version string and prints it incremented by one.
# Usage: increment_version <version> [<position>] [<leftmost>]
increment_version() {
   local usage=" USAGE: $FUNCNAME [-l] [-t] <version> [<position>] [<leftmost>]
           -l : remove leading zeros
           -t : drop trailing zeros
    <version> : The version string.
   <position> : Optional. The position (starting with one) of the number 
                within <version> to increment.  If the position does not 
                exist, it will be created.  Defaults to last position.
   <leftmost> : The leftmost position that can be incremented.  If does not
                exist, position will be created.  This right-padding will
                occur even to right of <position>, unless passed the -t flag."

   # Get flags.
   local flag_remove_leading_zeros=0
   local flag_drop_trailing_zeros=0
   while [ "${1:0:1}" == "-" ]; do
      if [ "$1" == "--" ]; then shift; break
      elif [ "$1" == "-l" ]; then flag_remove_leading_zeros=1
      elif [ "$1" == "-t" ]; then flag_drop_trailing_zeros=1
      else echo -e "Invalid flag: ${1}\n$usage"; return 1; fi
      shift; done

   # Get arguments.
   if [ ${#@} -lt 1 ]; then echo "$usage"; return 1; fi
   local v="${1}"             # version string
   local targetPos=${2-last}  # target position
   local minPos=${3-${2-0}}   # minimum position

   # Split version string into array using its periods. 
   local IFSbak; IFSbak=IFS; IFS='.' # IFS restored at end of func to                     
   read -ra v <<< "$v"               #  avoid breaking other scripts.

   # Determine target position.
   if [ "${targetPos}" == "last" ]; then 
      if [ "${minPos}" == "last" ]; then minPos=0; fi
      targetPos=$((${#v[@]}>${minPos}?${#v[@]}:$minPos)); fi
   if [[ ! ${targetPos} -gt 0 ]]; then
      echo -e "Invalid position: '$targetPos'\n$usage"; return 1; fi
   (( targetPos--  )) || true # offset to match array index

   # Make sure minPosition exists.
   while [ ${#v[@]} -lt ${minPos} ]; do v+=("0"); done;

   # Increment target position.
   v[$targetPos]=`printf %0${#v[$targetPos]}d $((10#${v[$targetPos]}+1))`;

   # Remove leading zeros, if -l flag passed.
   if [ $flag_remove_leading_zeros == 1 ]; then
      for (( pos=0; $pos<${#v[@]}; pos++ )); do
         v[$pos]=$((${v[$pos]}*1)); done; fi

   # If targetPosition was not at end of array, reset following positions to
   #   zero (or remove them if -t flag was passed).
   if [[ ${flag_drop_trailing_zeros} -eq "1" ]]; then
        for (( p=$((${#v[@]}-1)); $p>$targetPos; p-- )); do unset v[$p]; done
   else for (( p=$((${#v[@]}-1)); $p>$targetPos; p-- )); do v[$p]=0; done; fi

   echo "${v[*]}"
   IFS=IFSbak
   return 0
}

echo `increment_version "v1.0-alpha4"`
exit
