#!/bin/bash


#TODO:
# 1) Upload folders by compressing them to .zip package
# 2) Upload multiple files by compressing them to .zip
# 3) Share With (related to shared folders inside common folder)

## Array for multilingual purposes
ZZZword=(
	"Tiesioginė nuoroda",								#0
	"neįkeltas į Dropbox <u>Public</u> katalogą.", 		#1
	"Ką norite daryti?",								#2
	"Failo dydis:",										#3
	"Veiksmas",											#4
	"Nieko",											#5
	"Kurti kopiją",										#6
	"Kurti nuorodą",									#7
	"Dropbox neįjungtas"								#8
	"Dropbox negali susisiekti su serveriu"				#9
	);

word=(
	"Direct link",										#0
	"is not in Dropbox's <u>Public</u> directory", 		#1
	"What do you want to do?",							#2
	"File size:",										#3
	"Action",											#4
	"Nothing",											#5
	"Make copy of file & upload",						#6
	"Make hardlink of file & upload",					#7
	"Dropbox is not running"							#8
	"Dropbox cannot connect to server"					#9
	);


if [ "$1" ]; then 
    if [ "$1" == "share_with" ];
        then
            SHARING_DIRS="$(ls -d \"$HOME/Dropbox/Bendrai naudojami/\"*/)";
    fi
    file="$1";
    FILESIZE=$(du -h "$file"|awk '{print $1}');
    FILENAME="${file##*/}"; 
    
    else URG_ERR="No file!"; 
fi

##-----------------------------------------------
function show_output(){ ##Show URL on the screen
	echo "show_output"
	#URL="<a href=\"$D_URL\">Tiesioginė nuoroda</a>\n$D_URL\n\n$FILENAME\t\t\t$FILESIZE";
	URL="<a href=\"$D_URL\"> ${word[0]} </a>\n$D_URL\n\n$FILENAME\t\t\t$FILESIZE";
	total_output="$URL $warn";
	
	[ "$1" ] && total_output="$1";

	zenity --info --title "Dropbox" --text "$total_output";
}
##-----------------------------------------------
#################################################
##-----------------------------------------------
function check_dropbox_state(){
	FILE_IN_PUBLIC="$(echo \"$file\"|grep -i 'dropbox/public')";

	if [ ! "$DROPBOX_RUNS" ]; ## Generating warnings
	    then
	        #warn="\n\n<b>Dropbox is not running</b>";
	        warn="\n\n<b>${word[8]}</b>";
	    else if [ ! "$DROPBOX_WORKS" ];
	        then
	            #warn="\n\n<b>Dropbox cannot connect to server</b>";
	            warn="\n\n<b>${word[9]}</b>";
	        fi
	fi
}
##-----------------------------------------------
#################################################
##-----------------------------------------------
function copy_link_nothing_dialog(){
    #ans=$(zenity  --list  --text "\"$file\"\n is not in Dropbox's <u>Public</u> directory. \nWhat do you want to do?\n(Please be warned about the size: $FILESIZE)" --radiolist  --column " " --column "Veiksmas" TRUE Nieko FALSE "Kurti kopiją" FALSE "Kurti nuorodą");
    ans=$(zenity  --list  --text "\"$file\"\n ${word[1]}. \n${word[2]}\n(${word[3]} $FILESIZE)" --radiolist  --column " " --column "${word[4]}" TRUE ${word[5]} FALSE "${word[6]}" FALSE "${word[7]}");
        if [ ! "$ans" ] || [ "$ans" == "${word[5]}" ]; then exit; fi
        case "$ans" in
            "${word[6]}")
                cp -f "$file" "$dest"/"$FILENAME"; wait;
                ;;
            "${word[7]}")
                ln -f "$file" "$dest"/"$FILENAME"; wait; ##Symlinks ain't workin' - dropbox doesn't recognise them
                ;;
        esac
        [ ! -f "$dest/$FILENAME" ] && { 
			show_output "\n<b>File was not copied to $dest dir. Permissions issue?</b>\n"; 
			wait; 
			exit; 
			} || D_URL=$(dropbox puburl $dest/"$FILENAME");
}
##-----------------------------------------------
#################################################

## Directory where the file will be stored
dest="$HOME/Dropbox/Public/auto_uploaded";
mkdir -p $dest;


    DROPBOX_RUNS="$(ps -ef | grep -i dropbox | grep -v grep)";

    DStatus="$(dropbox status)";
    #DROPBOX_WORKS="$(echo $DStatus|grep -i index; echo $DStatus|grep -i upload; echo $DStatus|grep -i idle)";
    DROPBOX_WORKS="$(echo $DStatus|egrep -i "index|upload|idle|Up to date")";


check_dropbox_state;

if [ "$FILE_IN_PUBLIC" ] && [ ! "$URG_ERR" ]; ## Generating main message
    then
        D_URL=$(dropbox puburl "$file");
        echo $D_URL;
    else if [ ! "$URG_ERR" ]; ## If file is not in public -- ask what to do!
            then
                copy_link_nothing_dialog;
                
            else
                zenity --warning --title "Dropbox" --text "$URG_ERR";
                exit;
        fi
fi

show_output;

#url=$(dropbox puburl %f); err=$(echo $url|grep 'get public url'); if [  "$err" ]; then txt="$err"; else txt="<a href='$url'>Tiesioginė nuoroda</a>\n$url"; fi; zenity --info --title Dropbox --text "$txt"
