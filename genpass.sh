#!/bin/bash
# SCRIPT: method1.sh
# PURPOSE: Process a file line by line with PIPED while-read loop.

echo "Choose an option"
echo "0> Add new site"
count=0
cat ~/.genpass/pass_db | while read domain_info
do
	let count++

	IFS=',' read -a domain_columns <<< "$domain_info"
	echo "$count> ${domain_columns[0]^}"
done

read option


if  [ $option == 0 ]; then
	echo "Enter domain"
	read domain
	echo "Choose option"
	echo "0> No restrictions"
	echo "1> Short with special characters"
	echo "2> Short without special characters"
	read restrictions
	#not yet implemented.... do it by hand
	#cat ~/.genpass/pass_db | sed '$a/Text to append' > outFile
else
	domain_info=$(sed "${option}q;d" ~/.genpass/pass_db)
	IFS=',' read -a domain_columns <<< "$domain_info"
	domain=${domain_columns[0]}
	password_index=${domain_columns[1]}
	restrictions=${domain_columns[2]}

	echo "enter pass"
	read -s password
	#randa='GF3$8k44d;&(1&H'
	#randb='Ckj93#@ukockgoc'
	randa=$(sed "1q;d" ~/.genpass/pass_salt)
	randb=$(sed "2q;d" ~/.genpass/pass_salt)
	md5=$(echo -n $domain$randa$password_index$randb$password | md5sum | cut -f1 -d' ')

	#echo "Password"
	if [ $restrictions == 0 ]; then
		special_chars=$(echo ${md5:5:3} | tr 0-9A-Za-z \!\@\#\$\%\^\&\*)
		password=${md5:0:3}${special_chars}${md5:3}
	elif [ $restrictions == 1 ]; then
		special_chars=$(echo ${md5:5:3} | tr 0-9A-Za-z \!\@\#\$\%\^\&\*)
		first_char=$(echo ${md5:0:1} | tr 0-9 a-z)
		password=${first_char}${md5:0:4}${special_chars}${md5:9:4}
	elif [ $restrictions == 2 ]; then
		first_char=$(echo ${md5:0:1} | tr 0-9 a-z)
		password=${first_char}${md5:1:8}
	fi
	echo "Password saved to clipboard"
	echo $password | xclip -selection c # this saves the password so that outside applications can read the clipboard
	echo $password | xclip -i # this saves the password so that bash can read the clipboard
fi
