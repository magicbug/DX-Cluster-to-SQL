#!/bin/bash

TEST=`ps ax | grep '.spotsucker.' | grep -v 'grep'  ||  .spotsucker.`

if [ "$TEST" = "" ]; then
	echo "Error, Script not running..."
	nohup /usr/home/bwirel/public_html/dxcluster/start-spotsucker.sh &
else
	echo $TEST
	echo "Script läuft!"
fi

exit 0