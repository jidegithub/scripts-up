#!/bin/bash
#provision 3 docker containers running kibana v6.4.2, nginx server, & mysqlserver separately on each container
#solution should create 3 docker images and run the containers from them
#the 3 containers should be able to ping each other regardless of where it is being deployed

#containers
SQL_CONTAINER=mysql
SQL_CLIENT_CONTAINER=mysqlclient
NGINX_CONTAINER=mynginx
KIBANA_CONTAINER=mykibana

#networks
SQL_NETWORK=$SQL_CONTAINER-network
KIBANA_NETWORK=$KIBANA_CONTAINER-network
PING_NETWORK=ping-network

#stop all existing containers
stop_containers (){
  echo "stopping selected containers.." 
 docker stop $SQL_CONTAINER $NGINX_CONTAINER $KIBANA_CONTAINER
}
echo

stop_containers

#delete all existing network if they exist
echo "removing existing networks"
for network in $SQL_NETWORK $KIBANA_NETWORK $PING_NETWORK
do
 if docker network ls -f name=$network; then
   docker network rm $network
 fi
done
echo

#first, write a function that fetches and run mysql
get_mysql_image (){
  echo "pulling mysql image..."
  docker pull mysql:latest
}

create_sql_network (){
 echo "creating mysql network"
 docker network create $SQL_NETWORK
}

run_my_sql_server_container (){
 echo "running container..."
 if docker container inspect $SQL_CONTAINER >/dev/null 2>&1; then
  #if container exist
  docker rm $SQL_CONTAINER -f
 fi
  #container does not exist, create new one
  docker run -d --name $SQL_CONTAINER -e MYSQL_ROOT_PASSWORD=password -v /storage/mysql/mysql-datadir:/var/lib/mysql --rm mysql:latest
}

run_my_sql_client_container (){
 echo "running container..."
 if docker container inspect $SQL_CLIENT_CONTAINER >/dev/null 2>&1; then
  #if container exist
  docker rm $SQL_CLIENT_CONTAINER -f
 fi
  #container does not exist, create new one
  docker run -it --network $SQL_NETWORK --rm mysql mysql -h$SQL_CONTAINER -uexample-user -p
}

get_mysql_image
create_sql_network
run_my_sql_server_container
docker container ls -f name=^/$SQL_CONTAINER$

####################################################
echo

#second, write a function that fetches and run nginx
get_nginx_image (){
 echo "pulling nginx image..."
 docker pull nginx:latest
}

run_nginx_container (){
 echo "running container..."
 if docker container inspect $NGINX_CONTAINER >/dev/null 2>&1; then
  #if container exist
  docker rm $NGINX_CONTAINER -f
 fi
  #container does not exist, create new one
 docker run -d --name $NGINX_CONTAINER -p 80:80 nginx
}

get_nginx_image
run_nginx_container
docker container ls -f name=^/$NGINX_CONTAINER$

######################################################
echo

#third, write a function that fetches and run kibana
get_kibana_image (){ 
 echo "pulling kibana image..."
 docker pull kibana:6.4.2
}

create_kibana_network (){
 echo "creating kibana network"
 docker network create $KIBANA_NETWORK
}

run_kibana_container (){ 
 echo "running container..."
 if docker container inspect $KIBANA_CONTAINER >/dev/null 2>&1; then
  #if container exist
  docker rm $KIBANA_CONTAINER -f
 fi
  #container does not exist, create new one
  docker run -d --name $KIBANA_CONTAINER --net $KIBANA_NETWORK -p 5601:5601 kibana:6.4.2
}

get_kibana_image
create_kibana_network
run_kibana_container
docker container ls -f name=^/$KIBANA_CONTAINER$


#create a network that connect all services
docker network create $PING_NETWORK
#add all services/container to the ping network
docker network connect $PING_NETWORK $SQL_CONTAINER
docker network connect $PING_NETWORK $NGINX_CONTAINER
docker network connect $PING_NETWORK $KIBANA_CONTAINER
