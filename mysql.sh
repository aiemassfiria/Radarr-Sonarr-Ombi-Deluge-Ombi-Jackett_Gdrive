#!/bin/bash

# Install necessary packages
sudo apt install php
sudo apt install mysql-server
sudo apt install phpmyadmin

# Prompt for MySQL password
read -s -p "Enter MySQL password: " mysql_password
echo

# Drop root user and create new root user
mysql -u root -p$mysql_password <<EOF
DROP USER root@localhost;
CREATE USER root@localhost IDENTIFIED BY 'lowprofile1';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';
FLUSH PRIVILEGES;
EOF

# Connect to MySQL as root user
mysql -u root -p$mysql_password <<EOF
CREATE DATABASE smarterDB;
CREATE DATABASE ottDB;
CREATE USER 'massfiria'@'%' IDENTIFIED WITH mysql_native_password BY 'dagangsta';
CREATE USER 'ott'@'%' IDENTIFIED WITH mysql_native_password BY 'dagangsta';
CREATE TABLE smarterDB.profiles(username VARCHAR(50), password VARCHAR(50), name VARCHAR(50), port VARCHAR(50), usernameportal VARCHAR(50), passportal VARCHAR(50), token VARCHAR(50), host VARCHAR(50), id VARCHAR(50) UNIQUE);
CREATE TABLE smarterDB.users(username VARCHAR(50) UNIQUE, password VARCHAR(50), token VARCHAR(50), logged_in VARCHAR(50), isActivated VARCHAR(50), isRegistered VARCHAR(50), trial VARCHAR(50), expirationDate VARCHAR(50), showAds VARCHAR(50), shared_account VARCHAR(50));
CREATE TABLE smarterDB.url(username VARCHAR(50), password VARCHAR(50), list_name VARCHAR(50), list_url VARCHAR(255), list_id VARCHAR(255));
CREATE TABLE smarterDB.favourite(uniq VARCHAR(50), token VARCHAR(50), stream_type VARCHAR(50), id VARCHAR(50), stream_id VARCHAR(255), action VARCHAR(255), title VARCHAR(255), logo VARCHAR(255));
CREATE TABLE ottDB.profiles(username VARCHAR(50));
GRANT ALL ON smarterDB.* TO 'massfiria'@'%';
GRANT ALL ON ottDB.* TO 'ott'@'%';
EOF
