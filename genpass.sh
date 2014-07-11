#!/bin/bash
# SCRIPT: method1.sh
# PURPOSE: Process a file line by line with PIPED while-read loop.

declare calculated_password

function calc_password {
	# Expects two parameters 1: account line number, and 2: password
	domain_info=$(sed "${1}q;d" ~/.genpass/pass_db)
	IFS=',' read -a domain_columns <<< "$domain_info"
	category=${domain_columns[0]}
	domain=${domain_columns[1]}
	password_index=${domain_columns[2]}
	restrictions=${domain_columns[3]}
	password=${2}

	randa=$(sed "1q;d" ~/.genpass/pass_salt)
	randb=$(sed "2q;d" ~/.genpass/pass_salt)
	md5=$(echo -n $domain$randa$password_index$category$randb$password | md5sum | cut -f1 -d' ')

	if [ $restrictions == 0 ]; then
		special_chars=$(echo ${md5:5:3} | tr 0-9A-Za-z \!\@\#\$\%\^\&\*)
		calculated_password=${md5:0:3}${special_chars}${md5:3}
	elif [ $restrictions == 1 ]; then
		special_chars=$(echo ${md5:5:3} | tr 0-9A-Za-z \!\@\#\$\%\^\&\*)
		first_char=$(echo ${md5:0:1} | tr 0-9 a-z)
		calculated_password=${first_char}${md5:0:4}${special_chars}${md5:9:4}
	elif [ $restrictions == 2 ]; then
		first_char=$(echo ${md5:0:1} | tr 0-9 a-z)
		calculated_password=${first_char}${md5:1:8}
	fi

}

function get_password {
	#echo "Password Index: {$1}"; #for debugging purposes
	read -sp "Enter pass: " password
	calc_password "${1}" "${password}"

	echo "$calculated_password"
	echo "Password saved to clipboard"
	echo $calculated_password | xclip -selection c # this saves the password so that outside applications can read the clipboard
	echo $calculated_password | xclip -i # this saves the password so that bash can read the clipboard
}

declare -A password_array

read_password_db() {
	i=0

	while read line
	do
		IFS=',' read -a account_array <<< "$line"
		if ! [[ ${password_array[${account_array[0]}]} ]]; then 
			password_array["${account_array[0]}"]=""
		fi
		category_name="${account_array[0]}"
		old_value=${password_array["${category_name}"]}
		account_info_list[i]=$line # Put it into the array
		i=$(($i + 1))
		password_array["${category_name}"]="${old_value}$i,${line} "
	done < $1
}

ask_user_to_select_account() {
	echo "Choose an category"
	echo "0> Add new site"
	
	read_password_db ~/.genpass/pass_db

	count=0
	category_keys=( 'nil' )
	for category in "${!password_array[@]}"
	do
		category_keys+=( "${category}" )
		let count++
		echo "$count> ${category^}"
	done

	read category_index

	if [ $category_index == 0 ]; then
		echo "Feature Not Yet Implemented"
		exit 1
	elif [ $category_index -ge 1 -a $category_index -le ${#password_array[@]} ]; then
		category_key=${category_keys[$category_index]}
		echo "Choose an site from $category_key"
		echo "0> Add new site"

		account_list_string=${password_array["$category_key"]}
		IFS=' ' read -a account_list_array <<< "$account_list_string"

		count=0
		account_line_index=( )
		for account_data_string in "${account_list_array[@]}"
		do
			let count++
			IFS=',' read -a account_data_array <<< "$account_data_string"
			account_line_index+=(${account_data_array[0]})
			echo "$count> ${account_data_array[2]^}"
		done

		read site_index

		selected_site_index=${account_line_index[$site_index-1]}
	else
		echo "Unknown Response";
		exit 1;
	fi
}

if [ $# == 0 ]; then

	ask_user_to_select_account
	get_password $selected_site_index

elif [ $1 == 'export' ]; then
	echo "Not yet implemented";
	exit 1;
	while read -r -u 6 domain_info
	do
		let count++

		IFS=',' read -a domain_columns <<< "$domain_info"

		if [[ -z "${domain_columns[1]}" ]]; then
			echo "${domain_columns[4]}";
		else
			echo "${domain_columns[1]}";
		fi

	done 6< ~/.genpass/pass_db 

else
	while read -r -u 6 domain_info
	do
		let count++

		IFS=',' read -a domain_columns <<< "$domain_info"

		if [ "${domain_columns[4]}" = "$1" -o "${domain_columns[1]}" = "$1" ]; then
			get_password $count
		fi
	done 6< ~/.genpass/pass_db 
fi
