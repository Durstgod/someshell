#!/bin/sh
bind '"\t":menu-complete'


function get_disk()
{
    fdisk -l | grep "Disk /dev" | awk -F"[ :,]" '{print $2" "$4$5"\n"}'
}

function if_partitioned()
{
    if fdisk -l $1 | grep -q "$1""[1-9]"
    then
        return 0
    else
        return 1
    fi
 }

function print_disk_info()
{
     i=0
     for dev in "$@"
        do
            if [ ! -z `echo $dev | grep dev` ]
            then
                if if_partitioned $dev
                then
                    let i=i+2
                    echo "`expr $i / 2` $dev ${!i} partitioned"
                    
                else
                    let i=i+2
                    echo "`expr $i / 2` $dev ${!i} not partitioned"
                    
                fi    
            fi
        done

}

function if_number()
{
    if [[ $1 =~ ^[0-9]+$ ]]
    then 
        return 0
    else   
        return 1
    fi
}

function if_yes_no()
{
    ANS=`echo $1 | tr [A-Z] [a-z]`
    if [ ! -z $ANS ]
    then
    case $ANS in
        y|ye|yes) return 0
        ;;
        n|no) return 1
        ;;
    esac
    else 
        return 0
    fi
}

function if_directory()
{
if [ -d $@ ] 
then
	return 0
else
	return 1
fi
}

DISK_LIST1=`echo $(get_disk) | awk '{for(i=1;i<=NF;i+=2)print $i}'`
DISK_LIST=$(get_disk)
DISK_TOTAL=$(echo $DISK_LIST1 | wc -w)
echo $DISK_LIST
echo $DISK_TOTAL

print_disk_info $DISK_LIST
AAA=1
while [ $AAA != 0 ]
do
echo -n  "Please choose one disk to partition[1..$DISK_TOTAL]:"
read SELECTED_NO
if $(if_number $SELECTED_NO)
then
    if [ $SELECTED_NO -le $DISK_TOTAL ]
    then 
    AAA=0
    else
    echo "out of range, the number must in [1..$DISK_TOTAL]!"
    fi
else
    echo "you can only input numbers!" 
fi
done

SELECTED_DISK=`echo $DISK_LIST1 | awk -v a=$SELECTED_NO '{print $a}'`
echo "you selected $SELECTED_DISK"
fdisk $SELECTED_DISK <<EOF>/dev/null 2>&1
n




w
EOF


fdisk -l $SELECTED_DISK | tail -2
while true
do
    echo -n "do you want to format this partiton?[y..n][y]:"
    read IF_FORMAT
    IF_FORMAT=`echo $IF_FORMAT | tr [A-Z] [a-z]`
    if [ ! -z $IF_FORMAT ]
    then
        case $IF_FORMAT in
            y|ye|yes|n|no) if  `if_yes_no $IF_FORMAT`
                            then
                                IF_FORMAT=0
                                break
                            else
                                IF_FORMAT=1
                            break
                            fi
            ;;
            *) echo "wrong input"
        esac
    else
        IF_FORMAT=0
        break
    fi
done

SELECTED_PARTITION=`fdisk -l $SELECTED_DISK | tail -1 | awk '{print $1}'`
if [ $IF_FORMAT -eq 0 ]
then
    mkfs.ext4 $SELECTED_PARTITION >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        echo "$SELECTED_PARTITION formatted"
    else
        echo "something wrong"
    fi
fi



while true
do
    echo -n "do you want to mount the partition? [y..n][y]:"
    read IF_MOUNT
    IF_MOUNT=`echo $IF_MOUNT | tr [A-Z] [a-z]`
    if [ ! -z $IF_MOUNT ]
    then
        case $IF_MOUNT in
            y|ye|yes|n|no) if  `if_yes_no $IF_MOUNTT`
                            then
                                IF_MOUNT=0
                                break
                            else
                                IF_MOUNT=1
                            break
                            fi
            ;;
            *) echo "wrong input"
        esac
    else
        IF_MOUNT=0
        break
    fi
done

while true
do
    if [ $IF_MOUNT -eq 0 ]
    then   
        echo -n "please input the directory you want to mount:"
        read -e -p "" DIR
        if `if_directory $DIR`
        then 
            echo "the directory $DIR exists, mount here."
            break
        else
            mkdir $DIR
            if [ $? -eq 0 ]
            then
                echo "create the directory $DIR, mount here"
                break
            else
                echo "can not create the directory $DIR, try a new one"
            fi
        fi
    fi
done        
    
if if_directory $DIR
then
    mount $SELECTED_PARTITION $DIR
    if [ $? -eq 0 ]
    then
    echo "mount $SELECTED_PARTITION $DIR successful"
    else 
    echo "something wrong when mount"
    fi
else
    echo "connot mount to the directory $DIR"
fi
