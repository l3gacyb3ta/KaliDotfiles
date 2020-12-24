#!/usr/bin/bash
set -m #sets job control? WHAT DOES THIS DO????

#---------------------Battery stat functions-------------------------
#!/usr/bin/bash

#Percentage
Battery(){
	BATTACPI=$(acpi --battery)
	BATPERC=$(echo $BATTACPI | cut -d, -f2 | tr -d '[:space:]')

	if [[ $BATTACPI == *"100%"* ]]
	then
		echo -e -n "\uf00c $BATPERC"
	elif [[ $BATTACPI == *"Discharging"* ]]
	then
		BATPERC=${BATPERC::-1}
		if [ $BATPERC -le "10" ]
		then
			echo -e -n "\uf244"
		elif [ $BATPERC -le "25" ]
		then
			echo -e -n "\uf243"
		elif [ $BATPERC -le "50" ]
		then
			echo -e -n "\uf242"
		elif [ $BATPERC -le "75" ]
		then
			echo -e -n "\uf241"
		elif [ $BATPERC -le "100" ]
		then
			echo -e -n "\uf240"
		fi
		echo -e " $BATPERC%"
	elif [[ $BATTACPI == *"Charging"* && $BATTACPI != *"100%"* ]]
	then
		echo -e "\uf0e7 $BATPERC"
	elif [[ $BATTACPI == *"Unknown"* ]]
	then
		echo -e "$BATPERC"
	fi
}


#Gets wheather the battery is charging or not
BatStat(){
  if $(acpi -b | grep --quiet Discharging)
  then
      echo "-";
  else # acpi can give Unknown or Charging if charging, https://unix.stackexchange.com/questions/203741/lenovo-t440s-battery-status-unknown-but-charging
      echo "+";
  fi
}


#----------------------------Bits and bobs-------------------------
#Just the time
Clock(){
	TIME=$(date "+%H:%M:%S")
	echo -e -n " \uf017 ${TIME}"
}

#The current date
Cal() {
    DATE=$(date "+%a, %m %B %Y")
    echo -e -n "\uf073 ${DATE}"
}

#greps in nmap is ps aux, if it exists, set scanning
Nmap(){
	if [[ $(pgrep "nmap") ]]
	then
		echo "Scanning..."
	else
		echo "Not scanning"
	fi
}

#Wifi ssid and power meter
Wifi(){
	WIFISTR=$( iwconfig wlan0 | grep "Link" | sed 's/ //g' | sed 's/LinkQuality=//g' | sed 's/\/.*//g')
	if [ ! -z $WIFISTR ] ; then
		WIFISTR=$(( ${WIFISTR} * 100 / 70))
		ESSID=$(iwconfig wlan0 | grep ESSID | sed 's/ //g' | sed 's/.*://' | cut -d "\"" -f 2)
		if [ $WIFISTR -ge 1 ] ; then
			echo -e "\uf1eb ${ESSID} ${WIFISTR}%%"
		fi
	fi
}

WifiUpOrDown(){
	if [[ $(rfkill -r -n -o "soft,type" | grep "wlan" | grep --color="never" "blocked") == "blocked wlan" ]]
	then
		echo "Down"
	else
		echo "  Up"
	fi
}

#Not used, but turned into a oneliner in the main echo
WifiToggle(){
	if [[ $(rfkill -r -n -o "soft,type" | grep "wlan" | grep --color="never" "blocked") == "blocked wlan" ]]
	then
		rfkill unblock wlan
	else
		rfkill block wlan
	fi
}

#-----------------------------Window statistics---------------------------
#Gets the active window
ActiveWindow(){
	len=$(echo -n "$(xdotool getwindowfocus getwindowname)" | wc -m)
	max_len=70
	if [ "$len" -gt "$max_len" ];then
		echo -n "$(xdotool getwindowfocus getwindowname | cut -c 1-$max_len)..."
	else
		echo -n "$(xdotool getwindowfocus getwindowname)"
	fi
}

#Cool little workspace script
Workspaces(){
#Colors. In ANSII scape format
	RED='%{F#5EBDAB}' #actually green
	YELLOW='%{F#264B74}'

	list=`i3-msg -t get_workspaces | sed -e 's/\,"/\n/g' | grep name | sed -e 's/name"://g' -e 's/"//g' -e 's/.*://g'`
	list=($list)

	num=${#list[@]}

	focus=$(i3-msg -t get_workspaces | sed -e 's/\,"/\n/g' | grep focused | sed -e 's/focused"://g')
	focus=($focus)

	for ((i=0; i<${num}; i++)); do
	        cosa=${focus[i]}
	        if [ "$cosa" == 'true' ]; then
	        line="${line}$RED|${list[i]}|$NC"
	        else
	                line="${line}$YELLOW${list[i]}$NC "
	        fi
	        done
	echo -e $line
}

#echo -e "%{l}$(Nmap) %{A:pavucontrol:} Audio %{A} $(Workspaces)" "%{c}%{F#5EBDAB}$(ActiveWindow)%{F-} %{A:xdotool key super+Shift+Q:}    %{F#FF0000}Quit %{F-} %{A}" "%{r}%{A:if [[ \$(rfkill -r -n -o \"soft,type\" | grep \"wlan\" | grep --color=\"never\" \"blocked\") == \"blocked wlan\" ]];then;rfkill unblock wlan;else;rfkill block wlan;fi:} $(WifiUpOrDown)$(Wifi)%{A}  $(BatStat)$(Battery)  $(Clock) %{A:i3-scratchpad -d200x200 -abr -p0,-32 -wtu cal:}$(Cal)%{A}"

while true; do
	#           scan status            summons pavucntrl                            Current window                                                     Quit the app        wifi power  charging? percent       time                   summons calendar                   Date
	echo -e "%{l}$(Nmap) %{A:pavucontrol:} Audio %{A} $(Workspaces)" "%{c}%{F#5EBDAB}$(ActiveWindow)%{F-} %{A:xdotool key super+Shift+Q:}    %{F#FF0000}Quit %{F-} %{A}" "%{r}%{A:if [[ \$(rfkill -r -n -o \"soft,type\" | grep \"wlan\" | grep --color=\"never\" \"blocked\") == \"blocked wlan\" ]];then;rfkill unblock wlan;else;rfkill block wlan;fi:} $(WifiUpOrDown)$(Wifi)%{A}  $(BatStat)$(Battery)  $(Clock) %{A:i3-scratchpad -d200x200 -abr -p0,-32 -wtu cal:}$(Cal)%{A} %{A:sudo shutdown -h now:}Q%{A}"
	sleep 0.45s
done
