#!/bin/sh

fileout=${1}
cdate=`date +"%m-%d-%Y"`
rdir=`pwd`
#find the parser
jsonParser="$(dirname "$(find . -type f -name denseChangelog.sh | head -1)")"/DenseChangelog
# Check the date start range is set
#if [ -z "$sdate" ]; then
#    echo "!!!!---- Start date not defined ----!!!!"
#    echo "Please define a start date in mm/dd/yyyy format."
    #read sdate
    cd $jsonParser
    json=$(curl 'http://goo.im/json2&path=/devs/aokp/toro')
    javac -cp .:json-org.jar LastUpdateFinder.java
    java -cp .:json-org.jar LastUpdateFinder $json
    sdate=$(cat last_update_time)
    rm LastUpdateFinder.class last_update_time
    cd $rdir
#fi

# remove old changelogs
rm $rdir/denseChangelog_$cdate.txt > /dev/null;
rm $rdir/jsonChangelog_$cdate.txt > /dev/null;

# Find the directories to log
find $rdir -name .git | sed 's/\/.git//g' | sed 'N;$!P;$!D;$d' | while read line
do
    cd $line
    # Test to see if the repo needs to have a changelog written.
    log=$(git log --pretty="%H|%P|%an|%ad|%cn|%cd|%s|%B" --no-merges --since=$sdate --date-order)
    #log=$(git log --pretty="%an - %s" --no-merges --since=$sdate --date-order)
    project=$(git remote -v | head -n1 | awk '{print $2}' | sed 's/.*\///' | sed 's/\.git//')

    if [ -z "$log" ]; then
        echo "Nothing updated on $project, skipping"
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
        echo "¶$proj_credit|$project|" >> "$rdir"/denseChangelog_$cdate.txt
        echo "$log" | while read line
        do
             echo "$line" >> "$rdir"/denseChangelog_$cdate.txt
        done
        echo "" >> "$rdir"/denseChangelog_$cdate.txt
    fi
done

# move prompt to directory of our JSON parser
cd $jsonParser

# compile our parser
javac -cp .:json-org.jar ParseDenseChangelog.java

#if our compiler failes delete useless denseChangelog_$cdate.txt
if [ $? != 0 ]; then
    cd $rdir
    rm "$rdir"/denseChangelog_$cdate.txt
    exit 1
fi

outfile=$fileout
if [ -z "fileout" ]; then
    outfile="$rdir"/jsonChangelog_$cdate.txt
fi

# make dense changelog
java -cp .:json-org.jar ParseDenseChangelog "$rdir"/denseChangelog_$cdate.txt $outfile

# clean up
# move prompt back to original directory
cd $rdir
rm $jsonParser/ParseDenseChangelog.class
rm "$rdir"/denseChangelog_$cdate.txt

exit 0
