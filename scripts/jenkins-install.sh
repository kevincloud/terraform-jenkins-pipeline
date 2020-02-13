#!/bin/bash

#
# Update apt repo
#
echo "Add Jenkins repo..."
curl -sfLo "/root/jenkins.io.key" https://pkg.jenkins.io/debian/jenkins-ci.org.key
sudo apt-key add /root/jenkins.io.key
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# System updates

echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
echo "Updating apt repos..."
apt-get -y remove grub-pc
apt-get -y install grub-pc
update-grub
apt-get update > /dev/null 2>&1
echo "Updating system..."
# sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade > /dev/null 2>&1
apt-get -y upgrade > /dev/null 2>&1
echo "Installing additional software..."
apt-get -y install git jq openjdk-8-jdk python3 python3-pip npm docker.io maven jenkins > /dev/null 2>&1

echo "Adding AWS config..."
mkdir -p /root/.aws
sudo bash -c "cat >/root/.aws/config" <<EOF
[default]
aws_access_key_id=${AWS_ACCESS_KEY}
aws_secret_access_key=${AWS_SECRET_KEY}
EOF
sudo bash -c "cat >/root/.aws/credentials" <<EOF
[default]
aws_access_key_id=${AWS_ACCESS_KEY}
aws_secret_access_key=${AWS_SECRET_KEY}
region=${AWS_REGION}
EOF

echo "Installing AWS CLI..."
pip3 install botocore
pip3 install boto3
pip3 install awscli

sudo bash -c "cat >>/etc/environment" <<EOF

BEARER_TOKEN="${BEARER_TOKEN}"
ASSET_BUCKET="${ASSET_BUCKET}"
TF_ORGNAME="${TF_ORGNAME}"
TF_WORKSPACE="${TF_WORKSPACE}"
AWS_REGION="${AWS_REGION}"
EOF

sudo bash -c "cat >>/etc/bash.bashrc" <<EOF

export BEARER_TOKEN="${BEARER_TOKEN}"
export ASSET_BUCKET="${ASSET_BUCKET}"
export TF_ORGNAME="${TF_ORGNAME}"
export TF_WORKSPACE="${TF_WORKSPACE}"
export AWS_REGION="${AWS_REGION}"
EOF

source /etc/bash.bashrc

echo "Get public IP..."
export PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

echo "Download Jenkins config..."
aws s3 cp s3://hc-downloadable-assets/jenkins.tgz /var/lib/jenkins/jenkins.tgz

echo "Configure Jenkins..."
cd /var/lib/jenkins/
tar -xvf /var/lib/jenkins/jenkins.tgz -C /var/lib/jenkins

sudo bash -c "cat >/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml" <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<jenkins.model.JenkinsLocationConfiguration>
  <jenkinsUrl>http://$PUBLIC_IP:8080/</jenkinsUrl>
</jenkins.model.JenkinsLocationConfiguration>
EOF

# Start Jenkins
echo "Start Jenkins..."
systemctl enable jenkins
service jenkins start

echo "All done!"

