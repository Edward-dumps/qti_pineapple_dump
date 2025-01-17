#!/vendor/bin/sh
# Copyright (c) 2020 The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Enable various ufs ftrace debugging events
tracefs=/sys/kernel/tracing
ufs_node=$(ls /sys/bus/platform/devices/ | grep ufshc)
dbg=`cat /sys/bus/platform/devices/$ufs_node/qcom/dbg_state`

if [ -d $tracefs -a "$dbg" = 1 ]; then
    mkdir $tracefs/instances/ufs
    ufsevent=$tracefs/instances/ufs/set_event

    echo ufshcd_clk_gating > $ufsevent
    echo ufshcd_clk_scaling >> $ufsevent
    echo ufshcd_runtime_suspend >> $ufsevent
    echo ufshcd_runtime_resume >> $ufsevent
    echo ufshcd_system_suspend >> $ufsevent
    echo ufshcd_system_resume >> $ufsevent
    echo ufshcd_command >> $ufsevent

    # scsi
    echo dispatch_cmd_start >> $ufsevent
    echo scsi_dispatch_cmd_start >> $ufsevent
    echo scsi_dispatch_cmd_error >> $ufsevent
    echo scsi_dispatch_cmd_done >> $ufsevent
    echo scsi_dispatch_cmd_timeout >> $ufsevent
fi

#read ufs mcq node.
value=$(cat /sys/module/ufshcd_core/parameters/use_mcq_mode)

#set the io-scheduler to bfq and slice idle to 0 for all non-mcq support devices.
if [ "$value" != "Y" ]; then
	for sd_device in /sys/block/sd*/queue/scheduler;
	do
		echo bfq > $sd_device
	done
	#set the slice_idle to 0 for UFS SSD's.
	for slice_idle in /sys/block/sd*/queue/iosched/slice_idle;
	do
		echo 0 > $slice_idle
	done
fi
