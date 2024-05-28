#! /vendor/bin/sh
#
# Copyright (c) 2020, Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.


do_ps() {
  psStatus=`getprop vendor.fda.ps.status`
  if ["$psStatus" == "true"];then
      exit 1;
  fi
  setprop vendor.fda.ps.status "true"
  path=`getprop vendor.fda.property`
  echo >$path
  ps -A|grep -v \] > /data/local/tmp/command_output.txt
  while IFS= read -r line; do
    echo $line
    pid=`echo $line | awk '{print $2}'`
    echo $pid $process_name  $comm_name
    process_name=`echo $line | awk '{print $9}'`
    comm_name=`cat /proc/$pid/comm`
    echo $pid,$process_name,$comm_name >> $path
  done < /data/local/tmp/command_output.txt
  setprop vendor.fda.ps.status "false"
  setprop vendor.fda.status "ps output is successfully written"
}

enable_malloc_debug() {
  setenforce 0
  chmod 0777 /data/local/tmp
  process_to_enable=`getprop libc.debug.malloc.program`
  old_pid=`pgrep -f $process_to_enable`
  kill -9 $old_pid
  sleep 1
  timer=`getprop vendor.fda.malloc.timer`
  while true;
        do
        new_pid=`pgrep -f $process_to_enable`
        if [ "$new_pid" == "$old__pid" ]; then
         setprop vendor.fda.status "couldn't restart process,wating"
         sleep 1
        else
         setprop vendor.fda.status "process restarted, malloc_debug enabled!"
         break
       fi
  done
  if [ "$timer" == "" ]; then
     exit 1;
  fi
  process_option_enable=`getprop libc.debug.malloc.options`
  if [ `echo $process_option_enable | grep -c "backtrace" ` -gt 0 ]
  then
         backtrace_trak_flag=1
  fi
  if [ "$backtrace_trak_flag" == "0" ]; then
    exit 3
  fi
  while true;
        do
        process_status=`getprop libc.debug.malloc`
        if [ "$process_status" == "0" ]; then
         exit 2;
        fi
        new_pid2=`pgrep -f $process_to_enable`
        kill -47 `pgrep -f $process_to_enable`; sleep $timer;
 done
}

enable_backtrace()
{
   process_to_enable=`getprop libc.debug.malloc.program`
   old_pid=`pgrep -f $process_to_enable`
   kill -45 $old_pid
   setprop vendor.fda.status "backtrace enabled"
}

dump_backtrace()
{
   process_to_enable=`getprop libc.debug.malloc.program`
   old_pid=`pgrep -f $process_to_enable`
   kill -47 $old_pid
   setprop vendor.fda.status "backtrace dump enabled"
}
disable_malloc()
{
   process_to_enable=`getprop libc.debug.malloc.program`
   old_pid=`pgrep -f $process_to_enable`
   setprop libc.debug.malloc.program ""
   setprop libc.debug.malloc.options ""
   setenforce 1
   kill -9 $old_pid
   setprop vendor.fda.status "malloc disabled"
}
enable_binder_debug()
{
   binder=`getprop vendor.fda.binder`
   binderAlloc=`getprop vendor.fda.binder.alloc`
   echo $binder > /sys/module/binder/parameters/debug_mask
   echo $binderAlloc >  /sys/module/binder_alloc/parameters/debug_mask
}
heap_dump()
{
   setenforce 0
   heapdump=`getprop vendor.fda.heap`
   log -t BOOT -p i "FDA heapdump: process_name :'$heapdump'"
   pid=`pgrep -f $heapdump`
   log -t BOOT -p i "FDA heapdump: pid :'$pid'"
   arrIN=(${pid//'\n'/ })
   for i in "${arrIN[@]}";
   do
       log -t BOOT -p i "FDA heapdump: pid inside for loop:'$i'"
       init.fda.am.sh dumpheap $i
       return_dumpheap=`echo $?`
       log -t BOOT -p i "FDA heapdump: return_heapdump = '$return_dumpheap'"
       sleep 0.5
   done
   setenforce 1
}
logcat_command_execute()
{
   chmod 0777 /data/local/tmp
   chmod 0777 /data/local
   logcat_option="$1"
   log -t BOOT -p i "FDA App : Logcat_commnad_execute Option :'$logcat_option'"
   system_time=$(date +"%T")
   z="logcat_"
   y="$z$logcat_option$system_time"
   log -t BOOT -p i "FDA App : final Logcat_commnad_execute Option :'$y'"
   timeout 5 /system/bin/logcat -b "$logcat_option"  >> /data/local/tmp/"$y"
}
logcat()
{
   logcat_option=`getprop vendor.fda.logcat`
   log -t BOOT -p i "FDA App: Logcat Options :'$logcat_option'"
   arrIN=(${logcat_option//:/ })
   for i in "${arrIN[@]}";
   do
      log -t BOOT -p i "FDA App : parsing logcat Options :'$i'"
      (logcat_command_execute "$i")&
      sleep 0.5
    done
}
coredump()
{
   setenforce 0
   mkdir /data/core
   chmod 0777 /data/core/
   /system/bin/remount
   return_remount=`echo $?`
   echo 'persist.debug.trace=1' >> /system/build.prop
   log -t BOOT -p i "coredump : return_remount : '$return_remount'"
   /system/bin/reboot
}
coredump_disable_verity()
{
   setenforce 0
   umask 0
   /system/bin/disable-verity
   return_disable_verity=`echo $?`
   log -t BOOT -p i "coredump : return_remount : '$return_disable_verity'"
   /system/bin/reboot
}
coredump_bootup_func()
{
   setenforce 0
   log -t BOOT -p i "coredump_setenforce :"
   mkdir /data/core 0777 root root
   echo '/data/core/%E.%p.%e' >> /proc/sys/kernel/core_pattern
}


# entry point

command=`getprop vendor.fda.property`
command_file="/data/local/tmp/command.txt"
echo $command > $command_file

if grep "emulated" $command_file
then
      do_ps
elif grep "malloc_debug" $command_file
then
      enable_malloc_debug
elif grep "do_kill_enable_backtrace" $command_file
then
      enable_backtrace
elif grep "do_kill_enable_dump_backtrace" $command_file
then
      dump_backtrace
elif grep "do_kill_enable_disable_malloc" $command_file
then
      disable_malloc
elif grep "binder_debug" $command_file
then
      enable_binder_debug
elif grep "coredump" $command_file
then
      coredump
elif grep "heap_dump" $command_file
then
      heap_dump
elif grep "logcat" $command_file
then
      logcat
elif grep "my_disable_verity" $command_file
then
      coredump_disable_verity
elif grep "my_setenforce" $command_file
then
      coredump_bootup_func
fi
