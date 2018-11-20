#!/bin/bash


buildProducer() {
   gradleIfAvailable "KafkaTimestampProducer" "kafka-producer"
}


buildKStream() {
   gradleIfAvailable "KafkaCutpipeKStream" "kafka-kstream"
}

buildConsumer() {
   gradleIfAvailable "KafkaTimestampConsumer" "kafka-consumer"

}


gradleIfAvailable() {
	dir=$1
	if [[ -d $dir ]]; then
		pushd $dir
		
		docker stop $2 || echo "$2 was not created/running, no stop necessary"
		echo "Removing container $2, to get it updated - containers are sticky to their build hash"
		docker container rm $2


		echo "building current dir `pwd`"
		./gradlew jibDockerBuild || exit 1
		popd
	fi
}

checkAndStartDocker() {
	if (! docker stats --no-stream ); then
  		# On Mac OS this would be the terminal command to launch Docker
  		#open /Applications/Docker.app
 		#Wait until Docker daemon is running and has completed initialisation
		#while (! docker stats --no-stream ); do
			# Docker takes a few seconds to initialize
  		#	echo "`date` sleep"
		#	sleep 10
		#	echo "`date` wake up"
		#done
		#echo "`date`started"
		echo "please start docker and restart the script"
		exit 1
	fi

}



removeAllImages() {
	echo "stopping and removing existing images"
	### stopping possibly running containers
	docker ps | egrep -h "bastianbaist/kafka-consumer|bastianbaist/kafka-kstream|bastianbaist/kafka-producer|spotify/kafka" | awk '{print $1}' | xargs docker stop
	### removing the images
	docker image ls | egrep -h "kafka-producer|kafka-consumer|kafka-kstream|spotify/kafka" | awk '{print $3}' | xargs docker image rm --force
}

### script start
checkAndStartDocker
pubAddress=`ip route get 1 | awk '{print $NF;exit}' || exit 1`


### checking commandline args
for i in "$@"
do
	[ "--reset-all" -eq $i ] && echo "Removing created images"; removeAllImages
done

echo "All container were build"

echo "Using $pubAddress as IP"

docker pull spotify/kafka
[[ `docker container ls | grep " kafka" | wc -l` -eq "1" ]] && echo "Docker kafka container created" || echo "Creating spotify/kafka container server with name kafka";docker create -p 2181:2181 -p 9092:9092 --name kafka --env ADVERTISED_HOST=$pubAddress --env ADVERTISED_PORT=9092 spotify/kafka

echo "sleeping some time, to start kafka"
docker start kafka
echo "Starting docker spotify/Kafka container"

buildProducer
buildKStream
buildConsumer



sleep 30

[[ `docker container ls | grep " kafka-producer" | wc -l` -eq "1" ]] && echo "Docker kafka-producer container created" || echo "Creating bastianbaist/kafka-producer container with name kafka-procuer" ; docker create --name kafka-producer --env bootstrap.servers=$pubAddress:9092 bastianbaist/kafka-producer

[[ `docker container ls | grep " kafka-kstream" | wc -l` -eq "1" ]] && echo "Docker kafka-kstream container created" || echo "Creating bastianbaist/kafka-kstream container with name kafka-kstream" ; docker create --name kafka-kstream --env bootstrap.servers=$pubAddress:9092 bastianbaist/kafka-kstream


[[ `docker container ls | grep " kafka-consumer" | wc -l` -eq "1" ]] && echo "Docker kafka-consumer container created" || echo "Creating bastianbaist/kafka-consumer container with name kafka-consumer" ; docker create --name kafka-consumer --env bootstrap.servers=$pubAddress:9092 bastianbaist/kafka-consumer

docker start kafka-producer
docker start kafka-kstream
sleep 10
docker start kafka-consumer -a

