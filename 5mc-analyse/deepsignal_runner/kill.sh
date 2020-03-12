#!/bin/bash
pan=$1 
while true
do
date="echo `date`"
time=`$date|awk '{print$5}'`
hour1=`echo $time|cut -d':' -f1|sed -r 's/([0-9])([0-9])/\1/g'`
hour2=`echo $time|cut -d':' -f1|sed -r 's/([0-9])([0-9])/\2/g'`
if [ $hour1 -eq 0 ];then
hour=$hour2
else
hour=`echo $time|cut -d':' -f1`
fi
min1=`echo $time|cut -d':' -f2|sed -r 's/([0-9])([0-9])/\1/g'`
min2=`echo $time|cut -d':' -f2|sed -r 's/([0-9])([0-9])/\2/g'`
if [ $min1 -eq 0 ];then
min=$min2
else
min=`echo $time|cut -d':' -f2`
fi
tail -n5 log*/gpu*|grep "cuda"|awk '{print$2"-"$5}'|cut -d "|" -f 1|sed "s/\//_${pan}\//g"|while read inf
do
t1=`echo $inf|cut -d ':' -f1|sed -r 's/([0-9])([0-9])/\1/g'`
t2=`echo $inf|cut -d ':' -f1|sed -r 's/([0-9])([0-9])/\2/g'`
if [ $t1 -eq 0 ];then
t=$t2
else
t=`echo $inf|cut -d ':' -f1`
fi
m1=`echo $inf|cut -d ':' -f2|sed -r 's/([0-9])([0-9])/\1/g'`
m2=`echo $inf|cut -d ':' -f2|sed -r 's/([0-9])([0-9])/\2/g'`
if [ $m1 -eq 0 ];then
m=$m2
else
m=`echo $inf|cut -d ':' -f2`
fi
ptime=`echo $((($hour-$t)*60+$min-$m))`
pname=`echo $inf|cut -d '-' -f 2`
echo "[$time]" $ptime
if [ $ptime -ge 50 ];then
pstatus=1
else
pstatus=0
fi
echo $pstatus
if [ $pstatus -eq 1 ];then
kill `ps -ef|grep $pname|awk '{print$2}'`
echo "kill success " $pname
else
echo "no kill" $pname
fi
done
sleep 1800
done
