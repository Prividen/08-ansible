#! /bin/bash

CNT_INFO="
centos7|pycontribs/centos:7
ubuntu|pycontribs/ubuntu:latest
fedora|pycontribs/fedora:latest
"

function start_container() {
	NAME=$1
	IMG=$2
	docker run -dit --rm --name $NAME $IMG
}

function stop_container() {
	NAME=$1
	IMG=$2
	docker kill $NAME
}


function containers() {
	ACTION=$1_container
	for CNT in $CNT_INFO; do
		C_NAME=$(echo $CNT |cut -f1 -d '|') 
		C_IMG=$(echo $CNT |cut -f2 -d '|') 
		$ACTION $C_NAME $C_IMG
	done
}

containers start
ansible-playbook -i inventory/prod.yml site.yml --vault-pass-file vault.passwd
containers stop
