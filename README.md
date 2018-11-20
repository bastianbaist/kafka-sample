# kafka-sample
Meta repository, to prepare kafka server, a kafka producer sample, a kafka kstream sample and a kafka consumer sample and starts in docker

Clone this repository with submodules. 

## Installation pre requirements:
* (git) 
* docker (Running)
* iproute2 / iproute2mac 

## Steps to start:
* Clone this repository with git (git clone --recurse-submodules https://github.com/bastianbaist/kafka-sample.git)
* step into the created directory (cd kafka-sample)
* execute the run script (./run_kafka_demo.sh)

## options
* **--reset-all**: the easiest way to reset all docker container is to remove and recreate them. This option removes all used docker containers, pull/create the latest available Docker images and creates them again.
