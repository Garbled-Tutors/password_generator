echo "enter domain"
read domain
echo "enter pass"
read -s password
random='GF3$8k44d;&(1&H'
md5=$(echo -n $domain$random$password | md5sum | cut -f1 -d' ')
#echo $md5
echo $md5 | xclip -selection c
