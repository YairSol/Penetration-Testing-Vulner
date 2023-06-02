#!/bin/bash
echo ""
echo -e "\e[1;31;42m Penetration Testing Project \e[0m"
function RANGE()
{
 #~ Automatically identify the LAN network range
RANGE=$(ip addr |grep -i global  |awk '{print $2}' )
DIRECTORY=$(echo $RANGE | cut -b -12)
mkdir $DIRECTORY
cd $DIRECTORY
echo ""
echo -e "\e[32m\e[1m[+] Folder "$RANGE" has been created \e[0m"
echo ""
}


function SCAN()
{
	
	 #~ Enumerate each live host
	echo -e "\e[93m\e[1m[*] Starting host discovery..."
	echo""
	nmap "$RANGE" -sn |grep -i 'Nmap scan report for '|awk '{print $NF}' > hosts.lst 
	echo -e "\e[32m\e[1m[*] Starting service scan..."
	#~ Automatically scan the current LAN
	nmap "$RANGE" -sV -p- -oX nmap-service-scan.xml  1>/dev/null 
	nmap "$RANGE" -sV -p- -oN nmap-service-scan.txt  1>/dev/null 	
	for i in $(cat hosts.lst)

	do
		nmap $i -sV -p- -oN $i.service-scan.txt  1>/dev/null & wait

	done
	
}


function NSE
{

	#~ Find potential vulnerabilities for each device
	echo ""
	echo -e "\e[93m\e[1m[*] Scanning vulnerables"
	nmap "$RANGE" --script=vuln -oX nse-vuln.xml 1>/dev/null 
	for i in $(cat hosts.lst)
	do
		nmap $i --script=vuln -oN $i.vuln.txt 1>/dev/null & wait
	done
	
	echo ""
	echo -e "\e[32m\e[1m[*] starting brute force using nmap"
	nmap "$RANGE" --script=brute -oX nse-brute.xml  1>/dev/null 
	for i in $(cat hosts.lst)
	do
		 nmap $i --script=brute -oN $i.nse-brute.txt  1>/dev/null
	done
	
	echo ""
	echo -e "\e[93m\e[1m[*] Scanning for shared files"
	nmap "$RANGE" --script=smb-enum-shares -oX nse-shares.xml 1> /dev/null 
	for i in $(cat hosts.lst)
	do
		nmap $i --script=smb-enum-shares -oN $i.nse-shares.txt 1>/dev/null & wait
	done	
	
}


function SEARCHSPLOIT()
{
	echo ""
	echo -e "\e[32m\e[1m[*] Scanning vulnerabilities using searchsploit"
		searchsploit --nmap nmap-service-scan.xml > searchsploit.exploits.txt 2>/dev/null

}

function BRF()
{
	#~ Allow the user to create a password list
	echo ""
	#~ Allow the user to specify a user list
	echo -e "\e[93m\e[1m[+] Create a list of users to perform brute force and save by pressing the (Ctrl+D) button"
	cat > users.lst
	#~ Allow the user to specify a password list
	echo -e "\e[93m\e[1m[+] Create a list of passwords to perform brute force and save by pressing the (Ctrl+D) button"
	cat > pass.lst
	#~ If a login service is available, Brute Force with the password list [X]
	 #~ If more than one login service is available, choose the first service [X]
	 echo "=============================="
	cat nmap-service-scan.txt|grep -i open
	 echo "=============================="
	echo -e "\e[93m\e[1m[+] choose one of those services to preform brute force: " $SRV
	read SRV
	hydra -L users.lst -P pass.lst -M hosts.lst $SRV -o HydraResult.txt 1>/dev/null 2>/dev/null 



}

function HTML()
{
	echo ""
	echo -e "\e[32m\e[1m[+] creating HTML folder"
	mkdir HTML
	xsltproc nmap-service-scan.xml > nmap-service-scan.html
	xsltproc nse-vuln.xml > nse-vuln.html
	xsltproc nse-brute.xml > nse-brute.html
	xsltproc nse-shares.xml > nse-shares.html
	cp *html HTML
	rm *xml
	rm *html


}


function LOG()
#~ Display general statistics about the scan result
#~ Display general statistics (time of the scan, number of found devices, etc.) 
#~ Save all the results into a report [X]
#~ Allow the user to enter an IP address; display the relevant findings [X]
{
	DATE=$(date +%Y/%m/%d)
	echo "nmap scan date $DATE " > LOG.txt
	#~ number of open ports
	echo -e "\e[32m\e[1m[+] number of open ports" >>LOG.txt
	cat nmap-service-scan.txt |grep -i open |wc -l >>LOG.txt
	#~ number of found devices
	echo -e "\e[32m\e[1m[+] number of found devices" >>LOG.txt
	cat hosts.lst|wc -l >>LOG.txt
	echo "searcsploit scan date $DATE " >>LOG.txt
	#~ number of Smtp exploits 
	echo -e "\e[32m\e[1m[+] number of Smtp exploits" >>LOG.txt
	cat searchsploit.exploits.txt |grep -i smtp | grep -i smtp | sort | uniq | wc -l  >>LOG.txt
	#~ number of PostgreSQL exploits 
	echo -e "\e[32m\e[1m[+] number of PostgreSQL exploits" >>LOG.txt
	cat searchsploit.exploits.txt  | grep -i PostgreSQL |sort | uniq |wc -l >>LOG.txt
	#~ number of UnrealIRCd exploits 
	echo -e "\e[32m\e[1m[+] number of UnrealIRCd exploits" >>LOG.txt
	cat searchsploit.exploits.txt | grep -i UnrealIRCd |sort | uniq |wc -l >>LOG.txt
	#~ number of Telnet exploits 
	echo -e "\e[32m\e[1m[+] number of PostgreSQL exploits" >>LOG.txt
	cat searchsploit.exploits.txt  | grep -i Telnet |sort | uniq |wc -l >>LOG.txt
	#~ number of Ssh exploits 
	echo -e "\e[32m\e[1m[+] number of Ssh exploits" >>LOG.txt
	cat searchsploit.exploits.txt | grep -i OpenSSH |sort | uniq |wc -l >>LOG.txt
	#~ number of Ftp exploits 
	echo -e "\e[32m\e[1m[+] number of Ftp exploits" >>LOG.txt
	cat searchsploit.exploits.txt  | grep -i vsftpd |sort | uniq |wc -l >>LOG.txt
	#~ Hydra brute force result
	echo "brute force date $DATE " >>LOG.txt
	echo -e "\e[93m\e[1m[+] Hydra brute force result" >>LOG.txt
	cat HydraResult.txt |grep -i host  >>LOG.txt

}
function MENU()
{
    clear
    while [ "$EXIT" != EXIT ]
    do
    echo -e "\e[93m\e[1m[+] PRESS [H] - Hosts List Results (TXT)"
    echo -e "\e[93m\e[1m[+] PRESS [R] - Hydra Results (TXT)"
    echo -e "\e[93m\e[1m[+] PRESS [C] - Searchsploit Vulnerabilities Results (TXT)"
    echo -e "\e[93m\e[1m[+] PRESS [G] - Log file (TXT)"
    echo -e "\e[93m\e[1m[+] PRESS [E] - Nmap Service Scan Results (TXT)"
    echo -e "\e[93m\e[1m[+] PRESS [N] - Nmap Service Scan Results (HTML)" 
    echo -e "\e[93m\e[1m[+] PRESS [B] - Nse brute force Results (HTML)"
    echo -e "\e[93m\e[1m[+] PRESS [S] - Nse shares files Results (HTML)"
    echo -e "\e[93m\e[1m[+] PRESS [V] - Nse nse-vuln.html Results (HTML)"
    echo -e "\e[93m\e[1m[-] PRESS [X] - to exit ..."
    echo
    read -p "[!] Press whatever you want to see:" CH
    case $CH in
    H)
    clear
    echo "****************************************************************************"
    cat hosts.lst 
    echo "****************************************************************************"
    ;;
    R)
    clear
    echo "****************************************************************************"
	cat	HydraResult.txt 
	echo "****************************************************************************"
	;;
    C)
    clear
    echo "****************************************************************************"
    cat searchsploit.exploits.txt
    echo "****************************************************************************"
    ;;
    E)
    clear
    echo "****************************************************************************"
    cat nmap-service-scan.txt
    echo "****************************************************************************"
    ;;
    G)
    clear
    echo "****************************************************************************"
    cat LOG.txt
    echo "****************************************************************************"
    ;;
    N) 
    clear
	firefox HTML/nmap-service-scan.html 1>/dev/null 2>/dev/null &
    ;;
    B)
    clear
    firefox HTML/nse-brute.html 1>/dev/null 2>/dev/null &
    ;;
    S)
    clear
    firefox HTML/nse-shares.html 1>/dev/null 2>/dev/null &
    ;;
    V)
    clear
    firefox HTML/nse-vuln.html 1>/dev/null 2>/dev/null &
    ;;
    X)
    exit 
    ;;
    esac 
done
}
RANGE
SCAN
NSE
SEARCHSPLOIT
BRF
HTML
LOG
MENU

