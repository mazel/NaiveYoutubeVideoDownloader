#!/bin/bash
echo "initialize Script"
InputMySQLPwd=$1
export https_proxy=http://proxy.fhm.de:8080
while :
do

	# Get Another Video from MySQL
	echo "Get Video ID:"
	video_id=`mysql -uroot -p$InputMySQLPwd -hlocalhost -Dyoutube -se "SELECT video_id FROM videos WHERE video_status = 'C' LIMIT 1;" 2>/dev/null`

	if [[ -n "${video_id/[ ]*\n/}" ]]
	then
		checkLength=`curl https://www.youtube.com/$video_id 2>/dev/null | grep 'content="PT' | awk -v FS="(PT|M)" '{print $2}'`
		echo "Video Length Minutes: $checkLength"
		
		if [[ $checkLength -ne 0 ]]
		then
			echo "Video https://www.youtube.com/$video_id is too long. Skipping."
			#Update MySQL video_id to status too Long
			length=$checkLength*60
			cmd=`mysql -uroot -p$InputMySQLPwd -hlocalhost -Dyoutube -se "UPDATE videos SET video_status = 'L', length = $length WHERE video_id = '$video_id';" 2>/dev/null`

		else
			# Update Video to in Progress
			cmd=`mysql -uroot -p$InputMySQLPwd -hlocalhost -Dyoutube -se "UPDATE videos SET video_status = 'P' WHERE video_id = '$video_id';" 2>/dev/null`

			# Download Video 
			cmd=`youtube-dl https://www.youtube.com/$video_id -f bestvideo[ext=mp4]+bestaudio --prefer-ffmpeg --recode-video mp4 -o videos/$video_id`

			#Get Video Width and Height
			width=`ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height,width videos/$video_id.mp4 | grep width | awk -F"=" '{print $2}'`
			height=`ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height,width videos/$video_id.mp4 | grep height | awk -F"=" '{print $2}'`
			echo "Video Resolution: $width x $height"

			#Get Video Length
			length=`ffprobe -v error -show_entries format=duration   -of default=noprint_wrappers=1:nokey=1 videos/$video_id.mp4 | awk -F"." '{print $1}'`
			echo "Video Length: $length"

			#Update MySQL video_id to status Done
			cmd=`mysql -uroot -p$InputMySQLPwd -hlocalhost -Dyoutube -se "UPDATE videos SET video_status = 'D', x_res = $width, y_res = $height, length = $length WHERE video_id = '$video_id';" 2>/dev/null`
			echo "Video ID $video_id successfully processed."
		fi
	else
	    echo "No Video left to download. Going to sleep for 5 sec."
	    sleep 5
	fi

done




