#!/bin/bash
#provision 3 docker containers running kibana v6.4.2, nginx server, & mysqlserver separately on each container
#solution should create 3 docker images and run the containers from them
#the 3 containers should be able to ping each other regardless of where it is being deployed

# TO DO
# Organise functions
# Test


# Colour scheme
red='\033[31;40m'
green='\033[32;40m'
yellow='\033[33;40m'
reset='\033[0m'

# Containers
SQL_CONTAINER=mysql
SQL_CLIENT_CONTAINER=mysqlclient
NGINX_CONTAINER=mynginx
KIBANA_CONTAINER=mykibana

# Networks
SQL_NETWORK=$SQL_CONTAINER-network
KIBANA_NETWORK=$KIBANA_CONTAINER-network
PING_NETWORK=ping-network

# Dev null
VOID=/dev/null

## Checks and Setup ##

## Basic checks 
function basicCheck() {

  ## Test Internet Connectivity
  echo -ne "$yellow Testing for internet access..."
  sleep 2

  if nc -zw1 google.com 443;
    then
      echo -e "\r\033[K$green Internet OK $reset"
     else 
      echo -e "\r\033[K$red No Internet access $reset"
  fi

  # Test if user has docker installed
  echo -ne "$yellow Testing for Docker..."
  sleep 2
  which docker &> $VOID
  if [ $? -eq 0 ];
    then
      echo -e "\r\033[K$green Docker OK $reset"
     else 
      echo -e "\r\033[K$red Docker not installed \n\t Kindly install Docker $reset"
  fi
}

basicCheck

# Stop all existing containers if they exist
stop_containers (){
  echo -ne "$yellow Exiting running containers... $reset"
  sleep 1
  docker stop $NGINX_CONTAINER $SQL_CONTAINER $KIBANA_CONTAINER &> $VOID
  echo -e "\r\033[K$green Containers Exited $reset"
}

stop_containers

#delete all existing network if they exist
deleteNetworks() {
  echo -ne "$yellow Removing existing networks... $reset"
  sleep 1
  for network in $SQL_NETWORK $KIBANA_NETWORK $PING_NETWORK
    do
    if docker network ls -qf name=$network &> $VOID; 
      then
      docker network rm $network &> $VOID
    fi
done
  echo -e "\r\033[K$green Network removed $reset"
}

deleteNetworks

# First, write a function that fetches and run mysql
get_mysql_image () {
  echo -ne "$yellow Pulling MySQL image... $reset"
  sleep 2
  docker pull mysql:latest &> $VOID
}

# Create MySQL Network
create_sql_network () {
  echo -ne "\r\033[K $yellow Creating MySQL network... $reset"
  sleep 1
 docker network create $SQL_NETWORK &> $VOID
}

# Run MySQL Container
run_my_sql_server_container () {
  echo -ne "\r\033[K $yellow Running MySQL container... $reset"
  sleep 2
  docker container inspect $SQL_CONTAINER &> $VOID 
  if [ $? -eq 0 ]; 
    then
    #if container exist
      docker rm $SQL_CONTAINER -f &> $VOID
  fi
  #container does not exist, create new one
  docker run -d --name $SQL_CONTAINER -e MYSQL_ROOT_PASSWORD=password \
   -v /storage/mysql/mysql-datadir:/var/lib/mysql --rm mysql:latest &> $VOID

  # Test if container successfully starts up
  if [ $? -eq 0 ]; 
    then
      echo -e "\r\033[KMySQL container running as $SQL_CONTAINER $reset"
    else
      echo -e "\r\033[K$red Error: exit code $? $reset"
  fi
}

get_mysql_image
create_sql_network
run_my_sql_server_container

# Run Client container
run_my_sql_client_container () {
   echo -ne "\r\033[K $yellow Running MySQL container for client... $reset"
   sleep 1
   docker container inspect $SQL_CLIENT_CONTAINER &> $VOID; 
  if [ $? -eq 0 ]; 
    then
    #if container exist
    docker rm $SQL_CLIENT_CONTAINER -f &> $VOID
  fi
  #container does not exist, create new one
  docker run -it --network $SQL_NETWORK --rm mysql \
   mysql -h$SQL_CONTAINER -uexample-user -p &> $VOID

   # Test if container successfully starts up
  if [ $? -eq 0 ]; 
    then
      echo -e "\r\033[KMySQL container running as $SQL_CLIENT_CONTAINER $reset"
    else
      echo -e "\r\033[K$red Error: exit code $? $reset"
  fi
}

run_my_sql_client_container
docker container ls -f name=^/$SQL_CONTAINER$
sleep 2

# ####################################################
# echo
# sleep 2

#second, write a function that fetches and run nginx
get_nginx_image (){
  echo -ne "$yellow Pulling Nginx image... $reset"
  sleep 1
  docker pull nginx:latest
}

run_nginx_container (){
  echo -ne "\r\033[K $yellow Running Nginx container... $reset"
  sleep 2
  docker container inspect $NGINX_CONTAINER &> $VOID
  if [ $? -eq 0 ]; then
    #if container exist
    docker rm $NGINX_CONTAINER -f &> $VOID
  fi
  #container does not exist, create new one
 docker run -d --name $NGINX_CONTAINER -p 80:80 nginx &> $VOID

 if [ $? -eq 0 ]; 
    then
      echo -e "\r\033[KNginx container running as $NGINX_CONTAINER $reset"
    else
      echo -e "\r\033[K$red Error: exit code $? $reset"
  fi
}

get_nginx_image && \
run_nginx_container && \
docker container ls -f name=^/$NGINX_CONTAINER$
sleep 2

######################################################


#third, write a function that fetches and run kibana
get_kibana_image () { 
  echo -ne "$yellow Pulling Kibana image... $reset"
  docker pull kibana:6.4.2
}

create_kibana_network (){
  echo -ne "\r\033[K $yellow Creating Kibana network... $reset"
 docker network create $KIBANA_NETWORK
}

run_kibana_container (){ 
  echo "$green Running Kibana container... $reset"
  docker container inspect $KIBANA_CONTAINER &> $VOID 
  if [ $? -eq 0 ]; ; then
  #if container exist
    docker rm $KIBANA_CONTAINER -f &> $VOID
 fi
  #container does not exist, create new one
  docker run -d --name $KIBANA_CONTAINER --net \
   $KIBANA_NETWORK -p 5601:5601 kibana:6.4.2 &> $VOID

   if [ $? -eq 0 ]; 
    then
      echo -e "\r\033[KKibana container running as $KIBANA_CONTAINER $reset"
    else
      echo -e "\r\033[K$red Error: exit code $? $reset"
  fi
}

get_kibana_image && \
create_kibana_network && \
run_kibana_container && \
docker container ls -f name=^/$KIBANA_CONTAINER$
sleep 2

#create a network that connect all services
docker network create $PING_NETWORK

#add all services/container to the ping network
docker network connect $PING_NETWORK $SQL_CONTAINER
docker network connect $PING_NETWORK $NGINX_CONTAINER
docker network connect $PING_NETWORK $KIBANA_CONTAINER