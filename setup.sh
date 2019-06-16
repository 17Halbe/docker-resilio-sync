#!/bin/sh

new_sync()
{
	key=$( sudo docker exec -ti sync rslsync --generate-secret )
	echo "Enter the relative(will live its lonely life in /usr/share/resilio-sync/) or absolute folder path for the sync:"
	read sync_path
	case "$sync_path" in 
		/*) break;;
		*) sync_path="/usr/share/resilio-sync/$sync_path" ;;
	esac	
	while true; do
		echo "Enter a Name for the Sync:"
		read sync_name
		ls ./config/conf.d/$sync_name.conf > /dev/null 2>&1
		case "$?" in 
		2)  
		  echo "{
  \"secret\" : \"${key%?}\", // required field - use --generate-secret in command line to create new secret                                                     
  \"dir\" : \"$sync_path\", // * required field  ----> Relative Paths will be put in /usr/share/resilio-sync/ <----
  \"search_lan\" : false,                                                                                     
  \"use_sync_trash\" : true, // enable SyncArchive to store files deleted on remote devices                                             
  \"overwrite_changes\" : false, // restore modified files to original version, ONLY for Read-Only folders 
  \"use_relay_server\" : true, //  use relay server when direct connection fails
  \"use_tracker\" : true
}" > ./config/conf.d/$sync_name.conf
		  echo "File created successfully!"; break
		;;
		*) echo "File exists. Please use a different name!" 
		;;
		esac 
	done
	
	echo "The new secret is: $key"
}

setup_sync()
{
	echo "Enter the secret key:"
	read key
	echo "Enter the relative(will live its lonely life in /usr/share/resilio-sync/) or absolute folder path for the sync:"
	read sync_path
	case "$sync_path" in 
		/*) break;;
		*) sync_path="/usr/share/resilio-sync/$sync_path" ;;
	esac	
	while true; do
		echo "Enter a Name for the Sync:"
		read sync_name
		ls ./config/conf.d/$sync_name.conf > /dev/null 2>&1
		case "$?" in 
		2)  
		  echo "{
  \"secret\" : \"${key%?}\", // required field - use --generate-secret in command line to create new secret                                                     
  \"dir\" : \"$sync_path\", // * required field  ----> Relative Paths will be put in /usr/share/resilio-sync/ <----
  \"search_lan\" : false,                                                                                     
  \"use_sync_trash\" : true, // enable SyncArchive to store files deleted on remote devices                                             
  \"overwrite_changes\" : false, // restore modified files to original version, ONLY for Read-Only folders 
  \"use_relay_server\" : true, //  use relay server when direct connection fails
  \"use_tracker\" : true
}" > ./config/conf.d/$sync_name.conf
		  echo "File created successfully!"; break
		;;
		*) echo "File exists. Please use a different name!" 
		;;
		esac 
	done
}
delete_sync() 
{
	echo "Choose which folder you want to delete:"
	echo "!!!! C A U T I O N !!!!"
	echo "This action is not reversible! ALL data will be lost on this device. The sync key will be deleted."
	echo "THERE IS NO COMING BACK!"
	echo""
	echo "You have been warned..."
	/bin/cat ./config/conf.d/*.conf | grep \"dir\" | sed -e 's/.*: \"//' -e 's/\", \/\/ \*.*//' -e 's/\/$//'  -e 's/.*\///' 
	echo ""
	echo '     a  abort'
	echo '     q  quit'
	echo '     r  return'

	read folder
	case "$folder" in
		a|q|r) echo "aborting"
			;;
		*) filename=$(grep "\"dir\".*:.*\".*$folder.*\"," ./config/conf.d/* -l)
			if [ $? -ne 0 ]; then
				echo "Couldn't find $folder. Did you mistype?"
			else
				echo "found filename: $filename"
				echo "Do you really want to delete this sync: $folder [y|n]?"
				read input
				if [ "$input" = "y" ]; then
					sed '/'$folder'/,/}/ {/'$folder'/n;/}/!d}' $filename | tac |sed "/$folder/,/}/d" |tac > $filename.temp
					if [ $? -ne 0 ]; then
						echo "Couldn't perform deletion on $filename"
					else
						mv $filename.temp $filename
						docker exec -ti sync rm /usr/share/resilio-sync/$folder -R
						if [ $? -ne 0 ]; then
							echo "Couldn't delete folder(/usr/share/resilio-sync/$folder) inside the docker container."
						fi
					fi
				else 
					echo "aborting.."
				fi
			fi
		;;
	esac 
}

list_syncs()
{
	for f in ./config/conf.d/*.conf ; do
		echo "------$f :"
		while read p; do
				#echo "----------$p"
				case "$p" in
					*secret*) echo -n $p | sed -e 's/"secret"/Key/' -e 's/\/\/.*//' -e 's/ *//g' -e 's/,/ -> /' 
								;;	
					*\"dir\"*) echo $p | sed -e 's/.*: \"//' -e 's/\",.*//' -e 's/\/$//'  -e 's/.*\///' 
							;;
				esac
		done <$f

	done
}
#get_key()
#{

#}

choice=""

while [ "$choice" != "q" ]
do
        echo
        echo "Please make a selection!"
        echo "1) Generate new Sync-folder"
     	echo "2) Setup new sync with a known secret"
     	echo "3) Delete Sync folder"
     	echo "4) List synced folders and keys"
 #       echo "5) Get Read-only key of Volume"
        echo "q) Quit"
        echo

        read choice

        case $choice in
            '1') new_sync ;;
            '2') setup_sync ;;
			'3') delete_sync ;;
			'4') list_syncs ;;
			'5') get_key ;;
            'q') echo "quiting!" ;;
            *)   echo "menu item is not available; try again!" ;;
        esac
done