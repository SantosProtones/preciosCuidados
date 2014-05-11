#TODO list:
#	- Document.

fileName="$1"

if [ ! -f "$fileName" ]
	then
		echo "File not found"
		exit 1
	else
		exec 3< "$fileName"
		
		while read -r line
		do
			echo -e "$line"
		done <&3
		
		exec 3<&-
fi

exit 0