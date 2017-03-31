# Greenpeace Planet4 application Dockerfiles

![Planet4](https://cdn-images-1.medium.com/letterbox/300/36/50/50/1*XcutrEHk0HYv-spjnOej2w.png?source=logoAvatar-ec5f4e3b2e43---fded7925f62)

Dockerfiles and configuration files to build Planet4 wordpress based application.

## Requirements

To run this docker image it is mandatory to have a mysql instance working with
a database created and a user with access rights.

* docker >= 17.03.0-ce
* mysql 5.7

## Building

To build the container on your local system you just have to invoke the following
command from the directory containing the Dockerfile.

```bash
$ docker build . -t planet4:test
```
## Running the container

In order to run this container locally you must have a mysql instance running
beforehand. In the following example we will use the official mysql docker container
to set up the database.

First things first: pull the mysql official container
```bash
$ docker pull mysql
```
Now launch mysql container and create a username and database for the planet4
container environment

```bash
$ docker run -e MYSQL_ROOT_PASSWORD=test \
             -e MYSQL_DATABASE=planet4 \
             -e MYSQL_USER=planet4 \
             -e MYSQL_PASSWORD=test \
             mysql
```

```bash
$ docker run -e DBUSER=planet4 \
             -e DBPASS=test \
             -e DBNAME=planet4 \
             -e DBHOST=<mysql_container_ip>
             planet4:test
```

### Notes

There are few ways to extract the ip address and connecting containers.
Below is described a very simple method to obtain a container ip address.
For more information refer to the docker documentation.

Execute

```bash
$ docker ps
```
Grab the mysql container id

```bash
$ docker exec mysql_container_id ip addr show dev eth0
```
