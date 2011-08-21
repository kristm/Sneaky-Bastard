#!/bin/bash

# sparring.sh - checks if SneakyBastard is and should be up
# add this to your cron job to routinely check SneakyBastard status

isEnabled=`defaults read org.hellowala.sneakybastard enableSneaky`

echo `date`
if [ $isEnabled -eq 1 ];
then
    echo "Sneaky should be up"
    isUp=`ps aux|grep [S]neakyBastard|awk '{print $11}'`
    if [ -z $isUp ];
    then
        echo "But it is down... Force activate"
        userPref=`find ~/Library/PreferencePanes -name "SneakyBastard.prefPane" -print`
        systemPref=`find /Library/PreferencePanes -name "SneakyBastard.prefPane" -print`
        if [ $userPref ];
        then
            open ~/Library/PreferencePanes/SneakyBastard.prefPane/Contents/Resources/SneakyBastard.app
        elif [ $systemPref ];
        then
            open /Library/PreferencePanes/SneakyBastard.prefPane/Contents/Resources/SneakyBastard.app
        else
            echo "cant find SneakyBastard preference pane... Quitting"
        fi

    else
        echo "And it is up"
    fi
    echo "done"
else
    echo "Sneaky should be down"
fi
