#!/usr/bin/env bash
set -o nounset -o errexit -o pipefail
 
# run_sas.sh <support@dominodatalab.com>
# 2017-07-03
 
# How to send CLI parameters to SAS (http://blogs.sas.com/content/iml/2015/03/16/pass-params-sysget.html)
#    CLI: sas myprogram.sas -set key1 "value1" -set int2 42
#    SAS: %let key1 = %sysget(key1); /* "value1" */
#         %let int2 = %sysget(int2); /* 42 */
 
FILE=$1
if [[ $1 == *.sas ]]
then
    shift # Following a shift, the $@ holds the remaining command-line parameters, lacking the previous $1
    echo "Evaluating run_sas.sh for '$FILE' w/ arguments '$@'"
    if which wps >/dev/null
    then
        echo "Found WPS installed at `which wps`"
        echo "Executing '`which wps` < \"$FILE\"'"
        wps -stdio < "$FILE"
        echo "Finished executing '`which wps` -stdio < \"$FILE\"'"
    elif which sas >/dev/null
    then
        echo "Found SAS installed at `which sas`"
        echo "Executing '`which sas` \"$FILE\" -nodate -linesize 90 $@'"
        sas -stdio "$FILE" -nodate -linesize 90 $@
        echo "Finished executing '`which sas` -stdio \"$FILE\"'"
    else # run sas
        echo "We couldn't find SAS or WPS installed in this compute environment. Please contact support@dominodatalab.com if this is unexpected."
    fi
else
    echo "File '$FILE' not recognized by run_sas.sh. Please contact support@dominodatalab.com if this is unexpected."
fi
