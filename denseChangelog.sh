#!/bin/bash

# Usage:
#  From repo root ($TOP)
#  denseChangelog -v -d 10/11/12 -f myOutFile.json
#   Flags:
#     -v = verbose
#     -d = parse changelog from this date
#          (if not supplied we will attempt to
#           automatically find the last update date)
#           *optional*
#     -f = output file *optional*

today=`date +"%m-%d-%Y"`
rdir=`pwd`

# Find the parser
jsonParser="$(dirname "$(find . -type f -name denseChangelog.sh | head -1)")"/DenseChangelog

# Usage help screen
usageText="\n\nAOKP dense changelog generator... generates the json formatted change log"
usageText+="\n\nThis software is licensed under the Apache License v2"
usageText+="\n  for the full text look here: http://www.apache.org/licenses/LICENSE-2.0.txt"
usageText+="\n\nUsage denseChangelog.sh (-v) (-d MM-dd-yyyy) (-f /output/path/file.json)"
usageText+="\n\t*all flags are optional*"
usageText+="\n\n-v\t\t\t\tVerbose"
usageText+="\n-d MM-dd-yyyy\t\t\tGenerate changelog from date"
usageText+="\n-f /output/path/file.json\tPath to save dense formatted (json) changelog\n"
# get all flags
while getopts vd:hf: args
do
    case $args in
        v) verbose=true;;
        d) lastUpdate=$OPTARG;;
        f) fileout=$OPTARG;;
        # bail on invalid flags
        h) echo -e $usageText; exit 0;;
        ?) echo -e $usageText; exit 10;;
    esac
done

# if no date supplied then we look on goo.im for update date
if [ -z "$lastUpdate" ]; then
    echo "No date supplied looking on Goo.Im for latest update date"
    echo -e "To supply a custom date use flag -d MM/dd/yyyy\n"
    cd $jsonParser
    json=$(curl 'http://goo.im/json2&path=/devs/aokp/toro')
    echo -e "\n"
    javac -cp .:json-org.jar LastUpdateFinder.java
    java -cp .:json-org.jar LastUpdateFinder $json
    lastUpdate=$(cat last_update_time)
    rm LastUpdateFinder.class last_update_time
    cd $rdir
fi

# remove old changelogs
rm -q $rdir/denseChangelog_$today.json > /dev/null 2>&1;
rm -q $rdir/jsonChangelog_$today.json > /dev/null 2>&1;

# Find the directories to log
find $rdir -name .git | sed 's/\/.git//g' | sed 'N;$!P;$!D;$d' | while read line
do
    cd $line
    # Test to see if the repo needs to have a changelog written.
    log=$(git log --pretty="%H|%P|%an|%ad|%cn|%cd|%s|%B" --no-merges --since=$lastUpdate --date-order)
    project=$(git remote -v | head -n1 | awk '{print $2}' | sed 's/.*\///' | sed 's/\.git//')

    if [ -z "$log" ]; then
        if [ ! -z "$verbose" ]; then
            echo "Nothing updated on $project, skipping"
        fi
    else
        # Prepend group project ownership to each project.
        origin=`grep "$project" $rdir/.repo/manifest.xml | awk {'print $4'} | cut -f2 -d '"'`
        if [ "$origin" = "aokp" ]; then
            proj_credit=AOKP
        elif [ "$origin" = "aosp" ]; then
            proj_credit=AOSP
        elif [ "$origin" = "cm" ]; then
            proj_credit=CyanogenMod
        else
            proj_credit="No Project Associated"
        fi

        # Write the changelog
        echo "¶$proj_credit|$project|" >> "$rdir"/denseChangelog_$today.json
        echo "$log" | while read line
        do
             echo "$line" >> "$rdir"/denseChangelog_$today.json
        done
        echo "" >> "$rdir"/denseChangelog_$today.json
    fi
done

# move prompt to directory of our JSON parser
cd $jsonParser

# compile our parser
javac -cp .:json-org.jar ParseDenseChangelog.java

#if our compiler failes delete useless denseChangelog_$today.json
if [ $? != 0 ]; then
    cd $rdir
    rm "$rdir"/denseChangelog_$today.json
    exit 1
fi

outfile=$fileout
if [ -z "fileout" ]; then
    outfile="$rdir"/jsonChangelog_$today.json
fi

# make dense changelog
java -cp .:json-org.jar ParseDenseChangelog "$rdir"/denseChangelog_$today.json $outfile

# clean up
# move prompt back to original directory
cd $rdir
rm $jsonParser/ParseDenseChangelog.class
rm "$rdir"/denseChangelog_$today.json

exit 0
