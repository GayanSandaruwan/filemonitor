#!/bin/bash
remote_servers="52.14.235.17 18.223.108.20" 		# Space separated ip address of remote server

SCRIPTNAME=`basename "$0"`

print_help() {
	cat << EOF
Usage: $SCRIPTNAME filename
Also you need to set the ip addresses of remote server with space seprated.
Uses 'inotifywait' to sleep until 'filename' has been modified.

EOF
}

# check dependencies
if ! type inotifywait &>/dev/null ; then
	echo "You are missing the inotifywait dependency. Install the package inotify-tools (apt-get install inotify-tools)"
	sudo apt-get install inotify-tools
	# exit 1
fi

# parse_parameters:
while [[ "$1" == -* ]] ; do
	case "$1" in
		-h|-help|--help)
			print_help
			exit
			;;
		--)
			#echo "-- found"
			shift
			break
			;;
		*)
			echo "Invalid parameter: '$1'"
			exit 1
			;;
	esac
done

if [ "$#" != 1 ] ; then
	echo "Incorrect parameters. Use --help for usage instructions."
	exit 1
fi

FULLNAME="$1"
BASENAME=`basename "$FULLNAME"`
DIRNAME=`dirname "$FULLNAME"`

# coproc INOTIFY {
# 	inotifywait -q -m -e close_write,moved_to,create ${DIRNAME} &
# 	trap "kill $!" 1 2 3 6 15
# 	wait
# }

# trap "kill $INOTIFY_PID" 0 1 2 3 6 15

echo "Monitoring files at "$FULLNAME
cd $FULLNAME
inotifywait -e moved_to,create -m . |
while read -r directory events filename; do
  echo "$filename"
  ipfs_output=$(ipfs add "$filename")
  echo $ipfs_output
  ipfs_out_array=($ipfs_output)
  # echo ${ipfs_out_array[1]}
  ipfs_pin=$(ipfs pin add ${ipfs_out_array[1]})
  echo $ipfs_pin

  eval "remote_servers_arr=($remote_servers)"
  for server in "${remote_servers_arr[@]}"; do 
      echo "$server"
      ipfs_remote_pin=$(ssh -i test.pem ec2-user@$server "ipfs pin add ${ipfs_out_array[1]}")
  	  echo $ipfs_remote_pin
  done

done


# BUG! Não vai funcionar com arquivos contendo caracteres estranhos
# sed --regexp-extended -n "/ (CLOSE_WRITE|MOVED_TO|CREATE)(,CLOSE)? ${BASENAME}\$/q" 0<&${INOTIFY[0]}
