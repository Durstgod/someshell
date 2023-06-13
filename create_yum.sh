#!/bin/sh
DIR=/var/localrepo
function root_check()
{
_id=`id -u`
if [ $_id -eq 0 ]
then
	return 0
else 
	return 1
fi
}

function createrepo_install()
{
echo "createrepo not installed, do you want to install it now[y..n][y]:"
read _ANS
        
        case $_ANS in
        y|Y|[y,Y][e,E]|[y,Y][e,E][s,S])
                yum install -y createrepo >/dev/null 
                if [ $? -eq 0 ]
                then
                	echo "installed createrepo"
                	return 0
                else
                	echo "connot installed createrepo"
                	return 0
                	break
                fi
                ;;
        n|N|[n,N][o,O])
                echo " you need to intsall createrepo, processing stop"
                return 0
		break 
                ;;
                *) echo "wrong input"
		return 1
                ;;
        esac
}

function createrepo_check()
{
if `which createrepo >/dev/null 2>&1`
then 
	return 0
else 
	return 1
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



if root_check
then
	if createrepo_check
	then
		echo " you've installed createrepo"
	else
		
		while true
		do 
			createrepo_install
			if [ $? -eq 0 ]
			then
				break
		   	fi
		done
	fi
else
	echo " need root "
	break
fi	 

echo " now create the yum local repository directory"
echo -n "please input the directory [/var/local] :"
read DIR1
if [ -z $DIR1 ]
then DIR1=$DIR
fi

if `if_directory $DIR1`
then : 
else 
	mkdir $DIR1
fi

createrepo $DIR1 >/dev/null 2>&1
if [ $? -eq 0 ]
then
	echo '[local]
name=Local Repository
baseurl=file:///var/localrepo
enabled=1
gpgcheck=0' > /etc/yum.repos.d/local.repo
	if [ $? -eq 0 ]
	then
		yum makecache >/dev/null 2>&1
		if [ $? -eq 0 ]
		then
			yum list available --disablerepo=\* --enablerepo=local >/dev/null 2>&1
			if [ $? -eq 0 ]
			then
			echo " successful"
			else
			echo "something wrong"
			fi
		else 
			echo "failed makecache"
		fi
	else
		echo "failed to create local.repo"
	fi
	
else
	echo "failed to create yum index"
fi

