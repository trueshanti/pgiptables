#!/usr/bin/ash 

# I-Blocklist blacklists to iptables merger shell script
# Original by NiKaro127 (http://pastebin.com/u/NiKaro127), 1.12.2012
# initial version of the original script was licensed under the MIT license.
# Updated and modified by Jaka Smrekar (vinctux), 2015-16
# rewritten from scratch by trueshanti for KODI@librelec (BusyBox/ASH), 20190316
# changed License to GPLV3
# added to github : https://github.com/trueshanti/pgiptables
#


if [[ $USER != "root" ]]; then
	echo "This script must be run as root." 2>&1
	exit 1
fi

if [ `wget -q -T 5 -O /dev/null http://www.iblocklist.com` ] ; then
    echo "No functional Internet - aborting"
    exit 1
fi

# Blacklist's names & URLs arrays
bl_urls="http://list.iblocklist.com/?list=ydxerpxkpcfqjaybcssw&fileformat=p2p&archiveformat=gz@LVL1 
	http://list.iblocklist.com/?list=gyisgnzbhppbvsphucsw&fileformat=p2p&archiveformat=gz@LVL2 
	http://list.iblocklist.com/?list=uwnukjqktoggdknzrhgh&fileformat=p2p&archiveformat=gz@LVL3 
	http://list.iblocklist.com/?list=gihxqmhyunbxhbmgqrla&fileformat=p2p&archiveformat=gz@LVL4 
	http://list.iblocklist.com/?list=dgxtneitpuvgqqcpfulq&fileformat=p2p&archiveformat=gz@LVL5 
	http://list.iblocklist.com/?list=llvtlsjyoyiczbkjsxpf&fileformat=p2p&archiveformat=gz@LVL6 
	http://list.iblocklist.com/?list=cwworuawihqvocglcoss&fileformat=p2p&archiveformat=gz@LVL7 
	http://list.iblocklist.com/?list=mcvxsnihddgutbjfbghy&fileformat=p2p&archiveformat=gz@LVL8 
	http://list.iblocklist.com/?list=usrcshglbiilevmyfhse&fileformat=p2p&archiveformat=gz@LVL9 
	http://list.iblocklist.com/?list=xpbqleszmajjesnzddhv&fileformat=p2p&archiveformat=gz@LVL10"

BLURL=""
BLLVL=""
IPFILE=""
IPRANGE=""

for i in ${bl_urls}; do
	
	BLURL=`echo ${i} | cut -d @ -f 1`
	BLLVL=`echo ${i} | cut -d @ -f 2`
	GZFILE=/tmp/blacklist_${BLLVL}.gz
    
	echo "Downloading blacklist ${BLLVL} ..."
    wget -O ${GZFILE} "${BLURL}" -q	
	IPFILE="`basename ${GZFILE} .gz`"
	
	zcat ${GZFILE} | dos2unix > /tmp/${IPFILE}
	
	echo "Done downloading ${BLURL}."
	echo "Configuring iptables ..."
	iptables -D INPUT -j ${BLLVL}
	iptables -F ${BLLVL}
	iptables -X ${BLLVL}
	iptables -N ${BLLVL}
	iptables -A INPUT -j ${BLLVL}
	echo "Done configuring."

	echo "Applying blacklist ${BLLVL} to iptables ..."

    while IFS= read -r line <&3; do
        ### printf '%s\n' "${line}"
        IPRANGE=$( echo -n $line | cut -d: -f2 );
        if [ `echo "${IPRANGE}" | grep ^[0-9]` ] ;then
            iptables -w 2 -A ${BLLVL} -m iprange --dst-range ${IPRANGE} --src-range ${IPRANGE} -j DROP
		fi    
    done 3< /tmp/${IPFILE}

    echo "Blacklist ${BLLVL} successfully applied."

done

rm /tmp/blacklist*

exit 0
