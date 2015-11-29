i3status | (read line && echo $line && read line && echo $line && while :
do
read line
    dat=$(cat /etc/hostname)
    dat="[{ \"full_text\": \"${dat}\" },"
    echo "${line/[/$dat}" || exit 1
done)
