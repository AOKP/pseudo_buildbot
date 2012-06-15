#!/bin/sh

sdate=${1}
cdate=`date +"%m_%d_%Y"`
rdir=`pwd`

# Check the date start range is set
if [ -z "$sdate" ]; then
    echo "!!!!---- Start date not defined ----!!!!"
    echo "Please define a start date in mm/dd/yyyy format."
    read sdate
fi

# Find the directories to log
find $rdir -name .git | sed 's/\/.git//g' | sed 'N;$!P;$!D;$d' | while read line
do
    cd $line
    # Test to see if the repo needs to have a changelog written.
    log=$(git log --pretty="%an - %s" --since=$sdate --date-order)
    project=$(git remote -v | head -n1 | awk '{print $2}' | sed 's/.*\///' | sed 's/\.git//')
    if [ -z "$log" ]; then
    echo "Nothing updated on $project, skipping"
    else
    # Kinda not clean at all atm, but it'll do until I cleanup and
    # fully integrate it.
    echo "Project name: $project" >> "$rdir"/Changelog_$cdate.txt
    echo "" >> "$rdir"/Changelog_$cdate.txt
    echo "$log" >> "$rdir"/Changelog_$cdate.txt
    echo "" >> "$rdir"/Changelog_$cdate.txt
    echo "" >> "$rdir"/Changelog_$cdate.txt
    fi
done

exit 0
