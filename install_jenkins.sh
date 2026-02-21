#!/bin/bash
echo "starting jenkins installation"

sudo apt update
sudo apt install 

sudo apt install openjdk-17-jdk -y

echo "java complete"
echo"confirming version"

java -version

curl -fsSl

sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo app update
sudo app install jenkins

sudo systemctl enable jenkins

sudo systemctl start jenkins

sudo systemctl status jenkins


