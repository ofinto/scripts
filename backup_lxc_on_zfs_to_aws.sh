#!/bin/bash
DATE=`date +%Y-%m-%d`
ALL_LXC=0
ALL_SNAPSHOTS=0
VAULT=vault
SOURCE=(
"/data/host1/daily"
"/data/host2/daily"
"/data/host3/daily"
"/data/host4/daily"
"/data/host5/daily"
"/data/host6/daily"
)

for i in "${SOURCE[@]}"
do

for x in `zfs list -r $i | grep lxc | awk {'print $1'}`
do
        ALL_LXC=$[$ALL_LXC +1]
done;

for y in `zfs list -t snapshot -r $i | grep $DATE | awk {'print $1'}`
do
        name=$(echo $y | cut -d '/' -f 5)
        echo "Compression: $y"
        zfs send $y | pigz -7 > /data/other/aws/$name.gz
        echo "Send: $name"
        glacier-cmd upload $VAULT /data/other/aws/$name.gz
#       aws glacier upload-archive --account-id - --vault-name $VAULT --body /data/other/aws/$name.gz
        result=$?

        if [ $result == 0 ]; then
                echo "Delete local archive"
                rm /data/other/aws/$name.gz
        else
                echo "Upload FAILED"
        fi

        ALL_SNAPSHOTS=$[$ALL_SNAPSHOTS +1]
        sleep 600;
done;
done;
echo "All lxc fs on host: $ALL_LXC"
echo "Count snapshots on $DATE: $ALL_SNAPSHOTS"
