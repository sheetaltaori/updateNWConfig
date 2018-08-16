#!/bin/bash -e
## Run the script with user enabled with sudo access.
##

_MgmtSub="10.1"
_updateGW="GATEWAY="<Enter GATEWAY IP>""
_nwInt="/etc/sysconfig/network-scripts"
_nwDes="<Enter subnet destination>"
_envGW="<Enter GW value>"
_url="http://<IP>/repo/repodata/repomd.xml"


updateConfig()
{
_ensCnt=( $(ifconfig | awk '/^ens/{print $1}' | wc -l) )
echo $_ensCnt

_arrVal=( $(ifconfig | awk '/^ens/{print $1}' | tr -d :) )
echo ${_arrVal[@]}

for (( i=0; i<$_ensCnt; i++ ));
do
	_printIP=( $(ifconfig ${_arrVal[i]} | sed -n '/inet/,$p' | awk '{print $2}' | head -1) )
	echo ${_arrVal[i]} : $_printIP

	echo $_printIP| grep "^${_MgmtSub}"
	if [ $? = 0]
	then
		updateRouteDetails
		validURL
	else
		echo " $_printIP does not belong to management subnet"
	fi
done
}

updateRouteDetails()
{
echo $_updateGW >> $_nwInt/ifcfg-${_arrVal[i]}
echo $_nwDes via $_envGW dev ${_arrVal[i]} >> $_nwInt/route-${_arrVal[i]}
restartNW
}

restartNW()
{
echo "Restarting Network service"
sudo systemctl restart network 2> nwErr
if [ $? = 0 ]
then	
	echo "Network service restarted"
else
	echo "Error : Failed to start network service" && cat nwErr	
	exit 1
fi
}

validURL()
{
if 
	wget -S --spider $_url 2>&1 | grep 'HTTP/1.1 200 OK'
then
	echo "$_url Validated"
	repoUpdate
else
	echo "Invalid URL"
	Exit 1
fi
}

repoUpdate()
{
sudo cp $PWD/test.repo /etc/yum.repos.d/.
sudo rm -rf /etc/yum.repos.d/rh-cloud.repo
}

updateConfig