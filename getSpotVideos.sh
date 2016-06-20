#!/bin/bash
echo "initialize Script"
InputURL2Crawl=$2
InputMySQLPwd=$1
echo "crawling: "$InputURL2Crawl

# Parse URL for YouTube Videos
echo "curl "$InputURL2Crawl" | grep -E 'watch\?v=.{11}' -o"
cmd=`curl $InputURL2Crawl | grep -E 'watch\?v=.{11}' -o`
for vid_id in $cmd 
do
	#Add YouTube Video ID to MySQL with Status 'C' (To Download)
	echo "Adding Video ID: "$vid_id" to database."
	insert=`mysql -uroot -p$InputMySQLPwd -hlocalhost -Dyoutube -se "INSERT INTO videos (video_id, video_status) SELECT * FROM (SELECT '$vid_id', 'C') as tmp WHERE NOT EXISTS (SELECT video_id, video_status FROM videos WHERE video_id = '$vid_id') LIMIT 1;" 2>/dev/null`
	#echo $insert
done
