#!/bin/bash
# Однострочная команда для преобразования:
# sudo netstat -tunapl | awk '/firefox/ {print $5}' | cut -d: -f1 | sort | uniq -c |
# sort | tail -n5 | grep -oP '(\d+\.){3}\d+' | while read IP ; do whois $IP |
# awk -F':' '/^Organization/ {print $2}' ; done

#echo "Вывести все прослушивающие сокеты, порты TCP/UDP и имя приложения/программы"
#sudo netstat -tunapl
set -uxo pipefail
read -p "Имя процесса или номер PID:" prog 
echo -e "Запускать от root"
read -p "Yes/No (по-умолчанию no): " answer
read -p "Количество строк (по-умолчанию all): " lines

if [[ ! -z "$lines" && "$lines" =~ [^0-9]+ ]]; then
	echo "Только цифры"
	exit 2 
fi

ip_add() {
    netstat_result="$(netstat -tunapl | awk -v prog="$prog" '$0 ~ prog {print $5, $6, $7}'| sed -En 's/^([0-9.]+):.* ([A-Za-z_]+) ([0-9A-Za-z_/-]+).*/\1 \2 \3/p';)"
    if [[ ! -z "$netstat_result" ]]; then
        if [[ ! -z "$lines" ]]; then
            netstat_result="$(echo "$netstat_result" | head -n $lines)" ### Если ввели кол-во строк
        fi
    else
        echo "Процесс \"$prog\" не существует"
		### Если netstat_result пустой
        exit 4 
        
    fi
}

orgs(){ 
	### Проверка переменной $prog
	if [[ -z "$prog" ]]; then
		echo -e "All:"
	else
		echo -e "\n${prog}:"
	fi
	while read netstat_result; do		
		result="$(whois "$(echo $netstat_result | awk '{print $1}')" | awk -F':' '/^Organization/ {print $2}')"
		### Проверка organization
		if [[ ! -z "$result" ]]; then
			echo "$result $(echo $netstat_result | awk '{printf(" (Process: %s; netstat_result: %s; Count: %s; State: %s)", $4, $2, $1, $3)}')"
		else
			echo "   No organization $(echo $netstat_result | awk '{printf(" (Process: %s; netstat_result: %s; Count: %s; State: %s)", $4, $2, $1, $3)}')"
		fi
	done <<< "$netstat_result"
}

###Проверка SUDO
case $answer in
	"Yes"|"yes") 
				ip_add "sudo "
				orgs
				;;
	"No"|"no") 
				ip_add " "
				orgs
				;;
	[[:alnum:]]*)
				echo "Yes or No"
				exit 3 
				;;
	*)  ip_add " "
		orgs
				;;
esac