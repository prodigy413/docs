- amzn2_base_sv_builder.sh

~~~
# 2022/12/07 for project

#!/bin/bash

####################
# Variables
####################
declare -A OS_GROUPS;
OS_GROUPS=(
    ["INF_ADM"]=20000
    ["INF_OPE"]=20001
    ["APO_OPE"]=20002
)

PKGS=(
    "cronie-noanacron"
)

date

echo -e "\n##############################"
echo "# OS Setup"
echo -e "##############################\n"

echo -e "\n####################"
echo "PKG Setup"
echo -e "####################\n"
for PKG in ${PKGS[@]};
do
    sudo yum install -y $PKG
done
sudo yum check-update
sudo yum -y update

echo -e "\n####################"
echo "Cloud Init Setup"
echo -e "####################\n"
sudo cp /etc/cloud/cloud.cfg /tmp/`date "+%Y%m%d_%H%M%S"`_cloud.cfg
sudo sed -ie 's/ - default/#  - default/' /etc/cloud/cloud.cfg
sudo sed -ie 's/ssh_pwauth:\s*false/ssh_pwauth:   true/' /etc/cloud/cloud.cfg
sudo sed -ie 's/ - locale/# - locale/' /etc/cloud/cloud.cfg
sudo sed -ie 's/ - yum-add-repo/# - yum-add-repo/' /etc/cloud/cloud.cfg
sudo sed -ie 's/ - package-update-upgrade-install/# - package-update-upgrade-install/' /etc/cloud/cloud.cfg
echo -e '\n# This will cause the set+update hostname module to not operate (if true)\npreserve_hostname: true' | sudo tee -a /etc/cloud/cloud.cfg
sudo cat /etc/cloud/cloud.cfg | grep -e default -e ssh_pwauth -e locale -e yum-add-repo -e package-update-upgrade-install -e preserve_hostname

echo -e "\n####################"
echo "Password Setup"
echo -e "####################\n"
sudo cp /etc/pam.d/system-auth /tmp/`date "+%Y%m%d_%H%M%S"`_system-auth
sudo sed -ie 's/authtok_type=/authtok_type= minlen=12 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1/' /etc/pam.d/system-auth
sudo sed -ie 's/password\s*required\s*pam_deny.so/password    required      pam_deny.so\npassword    required      pam_pwhistory.so remember=3/' \
/etc/pam.d/system-auth
sudo cat /etc/pam.d/system-auth | grep password

sudo cp /etc/login.defs /tmp/`date "+%Y%m%d_%H%M%S"`_login.defs
sudo sed -ie 's/PASS_MAX_DAYS\s*99999/PASS_MAX_DAYS\t90/' /etc/login.defs
sudo cat /etc/login.defs | grep PASS_MAX_DAYS

echo -e "\n####################"
echo "Group Setup"
echo -e "####################\n"
for OS_GROUP in ${!OS_GROUPS[@]};
do
    sudo groupadd -g ${OS_GROUPS[$OS_GROUP]} $OS_GROUP
    sudo cat /etc/group | grep $OS_GROUP
done

echo -e "\n####################"
echo "Sudo Setup"
echo -e "####################\n"
sudo cp /etc/sudoers /tmp/`date "+%Y%m%d_%H%M%S"`_sudoers
sudo sed -ie 's/%wheel\s*ALL=(ALL)\s*ALL/%wheel\tALL=(ALL)\tALL\n\n## Allows people in group INF_ADM to run all commands\n%INF_ADM\tALL=(ALL)\tALL/' \
/etc/sudoers | sudo EDITOR='tee -a' visudo
sudo sed -ie 's/\/sbin:\/bin:\/usr\/sbin:\/usr\/bin/\/sbin:\/bin:\/usr\/sbin:\/usr\/bin:\/usr\/local\/bin/' /etc/sudoers | sudo EDITOR='tee -a' visudo
sudo cat /etc/sudoers | grep INF_ADM

echo -e "\n####################"
echo "SELINUX Setup"
echo -e "####################\n"
sestatus
getenforce
setenforce 0
sudo cp /etc/default/grub /tmp/`date "+%Y%m%d_%H%M%S"`_grub
sudo sed -ie 's/rd.shell=0/rd.shell=0 selinux=1 security=selinux enforcing=0 ipv6.disable=1/' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo cat /etc/default/grub | grep GRUB_CMDLINE_LINUX_DEFAULT

sudo cp /etc/selinux/config /tmp/`date "+%Y%m%d_%H%M%S"`_selinux_config
sudo sed -ie 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
sudo cat /etc/selinux/config | grep SELINUX=permissive
sestatus

echo -e "\n####################"
echo "SSH Setup"
echo -e "####################\n"
sudo cp /etc/ssh/sshd_config /tmp/`date "+%Y%m%d_%H%M%S"`_sshd_config
sudo sed -ie 's/#Port 22/Port 80\nPort 22/' /etc/ssh/sshd_config
sudo sed -ie 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -ie 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -ie 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -ie '/PasswordAuthentication no/d' /etc/ssh/sshd_config
sudo sed -ie 's/#ClientAliveInterval.*/ClientAliveInterval 10/' /etc/ssh/sshd_config
sudo sed -ie 's/#ClientAliveCountMax.*/ClientAliveCountMax 60/' /etc/ssh/sshd_config
sudo cat /etc/ssh/sshd_config | grep -e ^Port -e ^PasswordAuthentication -e ^PubkeyAuthentication -e ^PermitRootLogin -e ^ClientAlive
sudo systemctl reload sshd

echo -e "\n####################"
echo "Firewall Setup"
echo -e "####################\n"
systemctl status firewalld

echo -e "\n####################"
echo "Swap Setup"
echo -e "####################\n"
sudo swapon -s
sudo dd if=/dev/zero of=/swapfile bs=128M count=16
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon -s
sudo cp /etc/fstab /tmp/`date "+%Y%m%d_%H%M%S"`_fstab_01
echo '/swapfile                                     swap        swap   default           0   0' | sudo tee -a /etc/fstab
sudo cat /etc/fstab

echo -e "\n####################"
echo "Locale Setup"
echo -e "####################\n"
localectl
sudo localectl set-locale LANG=ja_JP.UTF-8
sudo localectl set-keymap jp106
localectl

echo -e "\n####################"
echo "Timezone Setup"
echo -e "####################\n"
date
sudo strings /etc/localtime
sudo timedatectl set-timezone Asia/Tokyo
timedatectl
sudo strings /etc/localtime
date

echo -e "\n####################"
echo "Runlevel Setup"
echo -e "####################\n"
systemctl get-default
sudo systemctl set-default multi-user.target
systemctl get-default

echo -e "\n####################"
echo "Disable IPv6 Setup"
echo -e "####################\n"
sudo cp /etc/sysctl.d/00-defaults.conf /tmp/`date "+%Y%m%d_%H%M%S"`_00-defaults.conf
echo -e '\n# Disable IPv6\nnet.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.d/00-defaults.conf
sudo cat /etc/sysctl.d/00-defaults.conf | grep net.ipv6.conf.

echo -e "\n####################"
echo "Service On/Off Setup"
echo -e "####################\n"
systemctl list-unit-files --no-pager | sort
sudo systemctl disable atd.service --now
sudo systemctl disable libstoragemgmt.service --now

echo -e "\n####################"
echo "AWS Command Setup"
echo -e "####################\n"
cd /tmp
curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install -i /opt/aws-cli -b /usr/local/bin
sudo rm -rf /tmp/aws*

echo -e "\n####################"
echo "CloudWatch Agent Setup"
echo -e "####################\n"
sudo yum install -y amazon-cloudwatch-agent
sudo echo -e "/var/log/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.log\n/var/log/amazon/ssm/amazon-ssm-agent.log\n{\n    missingok\n    rotate 4\n    weekly\n    create\n}" | sudo tee /etc/logrotate.d/aws
sudo cat /etc/logrotate.d/aws
sudo logrotate -d /etc/logrotate.d/aws

echo -e "\n####################"
echo "Last Update"
echo -e "####################\n"
sudo yum check-update
sudo yum -y update

date
~~~

- bastion_sv_builder_mcid1c1t.sh

~~~
# 2022/12/07 for project

#!/bin/bash

####################
# Variables
####################
SV_HOSTNAME="test-server-01"

declare -A USERS;
USERS=(
    ["sakurainaoto01c_N"]=20000
    ["sakurainaoto02c_N"]=20001
    ["sakurainaoto03c_N"]=20002
)

####################
# Start
####################
date

echo -e "\n##############################"
echo "# OS Setup"
echo -e "##############################\n"

echo -e "\n####################"
echo "HOSTNAME Setup"
echo -e "####################\n"
sudo hostnamectl set-hostname ${SV_HOSTNAME}
hostnamectl status

echo -e "\n####################"
echo "Add Users"
echo -e "####################\n"

for USER in ${!USERS[@]};
do
    sudo useradd -g 20000 -u ${USERS[$USER]} $USER
    echo xxxxxxxxxxx | sudo passwd --stdin $USER
done
sudo cat /etc/passwd
sudo cat /etc/shadow

echo -e "\n####################"
echo "CloudWatch Agent Setup"
echo -e "####################\n"
sudo sed -ie "s/{LOG_GROUP_ENV_NAME}/${ENV_NAME}/" /tmp/cloudwatch_agent_template.json
sudo mv /tmp/cloudwatch_agent_template.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
sudo systemctl enable amazon-cloudwatch-agent --now

echo -e "\n####################"
echo "Last Update"
echo -e "####################\n"
sudo yum check-update
sudo yum -y update

date
~~~

- parameter_collector.sh

~~~
# 2022/12/07 for project

#!/bin/bash

echo -e "\n##############################"
echo "# Get OS Parameter"
echo "# `date '+%Y/%m/%d %H:%M'`"
echo -e "##############################\n"

echo -e "\n\n####################"
echo "hostnamectl status"
echo -e "####################\n"
sudo hostnamectl status

echo -e "\n\n####################"
echo "/etc/cloud/cloud.cfg"
echo -e "####################\n"
sudo cat /etc/cloud/cloud.cfg

echo -e "\n\n####################"
echo "/etc/pam.d/system-auth"
echo -e "####################\n"
sudo cat /etc/pam.d/system-auth

echo -e "\n\n####################"
echo "/etc/login.defs"
echo -e "####################\n"
sudo cat /etc/login.defs

echo -e "\n\n####################"
echo "/etc/group"
echo -e "####################\n"
sudo cat /etc/group

echo -e "\n\n####################"
echo "/etc/sudoers"
echo -e "####################\n"
sudo cat /etc/sudoers

echo -e "\n\n####################"
echo "/etc/passwd"
echo -e "####################\n"
sudo cat /etc/passwd

echo -e "\n\n####################"
echo "/etc/shadow"
echo -e "####################\n"
sudo cat /etc/shadow

echo -e "\n\n####################"
echo "getenforce"
echo -e "####################\n"
getenforce

echo -e "\n\n####################"
echo "sestatus"
echo -e "####################\n"
sestatus

echo -e "\n\n####################"
echo "/etc/selinux/config"
echo -e "####################\n"
sudo cat /etc/selinux/config

echo -e "\n\n####################"
echo "/etc/default/grub"
echo -e "####################\n"
sudo cat /etc/default/grub

echo -e "\n\n####################"
echo "/etc/ssh/sshd_config"
echo -e "####################\n"
sudo cat /etc/ssh/sshd_config

echo -e "\n\n####################"
echo "Firewall (systemctl list-units)"
echo -e "####################\n"
systemctl list-units | grep -i firewalld

echo -e "\n\n####################"
echo "systemctl status (Firewall)"
echo -e "####################\n"
systemctl -t service --state=running --no-legend --no-pager | grep -i firewalld

echo -e "\n\n####################"
echo "systemctl status (amazon-ssm-agent)"
echo -e "####################\n"
systemctl -t service --state=running --no-legend --no-pager | grep -i amazon-ssm-agent

echo -e "\n\n####################"
echo "systemctl status (amazon-cloudwatch-agent)"
echo -e "####################\n"
systemctl -t service --state=running --no-legend --no-pager | grep -i amazon-cloudwatch-agent

echo -e "\n\n####################"
echo "/proc/version"
echo -e "####################\n"
sudo cat /proc/version

echo -e "\n\n####################"
echo "lscpu"
echo -e "####################\n"
lscpu

echo -e "\n\n####################"
echo "free -h"
echo -e "####################\n"
free -h

echo -e "\n\n####################"
echo "lsblk -r"
echo -e "####################\n"
lsblk -r

echo -e "\n\n####################"
echo "df -h"
echo -e "####################\n"
df -h

echo -e "\n\n####################"
echo "df -Th"
echo -e "####################\n"
df -Th

echo -e "\n\n####################"
echo "swapon -s"
echo -e "####################\n"
sudo swapon -s

echo -e "\n\n####################"
echo "/etc/fstab"
echo -e "####################\n"
sudo cat /etc/fstab

echo -e "\n\n####################"
echo "Locale"
echo -e "####################\n"
localectl

echo -e "\n\n####################"
echo "timedatectl"
echo -e "####################\n"
timedatectl

echo -e "\n\n####################"
echo "/etc/localtime"
echo -e "####################\n"
sudo strings /etc/localtime

echo -e "\n\n####################"
echo "Runlevel"
echo -e "####################\n"
systemctl get-default

echo -e "\n\n####################"
echo "/etc/sysctl.d/00-defaults.conf"
echo -e "####################\n"
sudo cat /etc/sysctl.d/00-defaults.conf

echo -e "\n\n####################"
echo "/etc/logrotate.d/aws"
echo -e "####################\n"
sudo cat /etc/logrotate.d/aws

echo -e "\n\n####################"
echo "sysctl -a"
echo -e "####################\n"
sudo sysctl -a | sort

echo -e "\n\n####################"
echo "yum list installed (cronie-noanacron)"
echo -e "####################\n"
yum list installed | grep -i cronie-noanacron

echo -e "\n\n####################"
echo "yum list installed (dos2unix)"
echo -e "####################\n"
yum list installed | grep -i dos2unix

echo -e "\n\n####################"
echo "yum list installed (nkf)"
echo -e "####################\n"
yum list installed | grep -i nkf

echo -e "\n\n####################"
echo "yum list installed (postgresql13-contrib)"
echo -e "####################\n"
yum list installed | grep -i postgresql13-contrib

echo -e "\n\n####################"
echo "yum list installed (redis6)"
echo -e "####################\n"
yum list installed | grep -i redis6

echo -e "\n\n####################"
echo "yum repolist all"
echo -e "####################\n"
yum repolist all

echo -e "\n\n####################"
echo "yum check-update"
echo -e "####################\n"
sudo yum check-update

echo -e "\n\n####################"
echo "/etc/resolv.conf"
echo -e "####################\n"
sudo cat /etc/resolv.conf

echo -e "\n\n####################"
echo "Git Command"
echo -e "####################\n"
git version

echo -e "\n\n####################"
echo "Terraform Command (tfenv list)"
echo -e "####################\n"
tfenv list

echo -e "\n\n####################"
echo "Terraform Command (terraform version)"
echo -e "####################\n"
terraform version

echo -e "\n\n####################"
echo "AWS Command"
echo -e "####################\n"
aws --version

echo -e "\n\n####################"
echo "kubectl Command"
echo -e "####################\n"
kubectl version --short --client

echo -e "\n\n####################"
echo "kubeseal Command"
echo -e "####################\n"
kubeseal --version

echo -e "\n\n####################"
echo "aws-vault Command"
echo -e "####################\n"
aws-vault --version

echo -e "\n\n####################"
echo "Scripts (ls -l update_route53.sh)"
echo -e "####################\n"
sudo ls -l /var/lib/cloud/scripts/per-instance/update_route53.sh

echo -e "\n\n####################"
echo "Scripts (ls -l mcidxxxx.sh)"
echo -e "####################\n"
sudo ls -l /etc/profile.d/mcid*

echo -e "\n\n####################"
echo "Scripts (ls -l mcid_audit.rules)"
echo -e "####################\n"
sudo ls -l /etc/audit/rules.d/mcid_audit.rules

echo -e "\n\n####################"
echo "Scripts (cat update_route53.sh)"
echo -e "####################\n"
sudo cat /var/lib/cloud/scripts/per-instance/update_route53.sh

echo -e "\n\n####################"
echo "Scripts (cat mcidxxxx.sh)"
echo -e "####################\n"
sudo cat /etc/profile.d/mcid*

echo -e "\n\n####################"
echo "Scripts (cat mcid_audit.rules)"
echo -e "####################\n"
sudo cat /etc/audit/rules.d/mcid_audit.rules

echo -e "\n\n####################"
echo "ls -la /external"
echo -e "####################\n"
ls -la /external

echo -e "\n\n####################"
echo "systemctl list-unit-files"
echo -e "####################\n"
systemctl list-unit-files --no-pager | sort

echo -e "\n\n####################"
echo "systemctl status"
echo -e "####################\n"
systemctl -t service --no-legend --no-pager | sort

echo -e "\n\n####################"
echo "rpm -qa"
echo -e "####################\n"
rpm -qa | sort

echo -e "\n##############################"
echo "# End"
echo "# `date '+%Y/%m/%d %H:%M'`"
echo -e "##############################\n"
~~~

- work01_base_sv_builder.sh

~~~
# 2022/12/07 for project

#!/bin/bash

####################
# Variables
####################
PKGS=(
    "amazon-efs-utils"
    "git"
)

####################
# Start
####################
date

echo -e "\n##############################"
echo "# OS Setup"
echo -e "##############################\n"

cd /tmp
pwd

echo -e "\n####################"
echo "PKG Setup"
echo -e "####################\n"
for PKG in ${PKGS[@]};
do
    sudo yum install -y $PKG
done
sudo yum check-update
sudo yum -y update

echo -e "\n####################"
echo "Git Setup"
echo -e "####################\n"
# sudo yum install -y git
git --version

echo -e "\n####################"
echo "Terraform Setup"
echo -e "####################\n"
sudo git clone https://github.com/tfutils/tfenv.git /opt/.tfenv
sudo ln -s /opt/.tfenv/bin/* /usr/local/bin
tfenv list-remote
sudo tfenv install 1.2.2
tfenv list
sudo tfenv use 1.2.2
terraform --version

echo -e "\n####################"
echo "Kubectl Setup"
echo -e "####################\n"
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl
curl -o kubectl.sha256 https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl.sha256
openssl sha1 -sha256 kubectl 
cat kubectl.sha256
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
sudo chown root:root /usr/local/bin/kubectl
kubectl version --short --client

echo -e "\n####################"
echo "Kubeseal Setup"
echo -e "####################\n"
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.1/kubeseal-0.18.1-linux-amd64.tar.gz
tar xvzf kubeseal-0.18.1-linux-amd64.tar.gz
sudo chown root:root kubeseal
sudo mv kubeseal /usr/local/bin/
ls -l /usr/local/bin/kubeseal
kubeseal --version

echo -e "\n####################"
echo "AWS Vault Setup"
echo -e "####################\n"
curl -sSL https://github.com/99designs/aws-vault/releases/download/v6.6.0/aws-vault-linux-amd64 -o ./aws-vault
chmod 755 ./aws-vault
sudo mv ./aws-vault /usr/local/bin/aws-vault
sudo chown root:root /usr/local/bin/aws-vault
aws-vault --version

echo -e "\n####################"
echo "Audit Setup"
echo -e "####################\n"
sudo ls -l /etc/audit/rules.d/audit.rules
sudo cat /etc/audit/rules.d/audit.rules
sudo sed -ie 's/-b 8192/#-b 8192/' /etc/audit/rules.d/audit.rules
sudo sed -ie 's/-f 1/#-f 1/' /etc/audit/rules.d/audit.rules
sudo cat /etc/audit/rules.d/audit.rules
sudo ls -l /etc/audit/rules.d/audit.rules

sudo ls -l /etc/audit/rules.d/
echo "# audit git push command execution" | sudo tee -a /etc/audit/rules.d/mcid_audit.rules
echo "" | sudo tee -a /etc/audit/rules.d/mcid_audit.rules
echo "" | sudo tee -a /etc/audit/rules.d/mcid_audit.rules
echo "# audit fopen of specific files including personal informations" | sudo tee -a /etc/audit/rules.d/mcid_audit.rules
echo "" | sudo tee -a /etc/audit/rules.d/mcid_audit.rules
sudo cat /etc/audit/rules.d/mcid_audit.rules
sudo ls -l /etc/audit/rules.d/mcid_audit.rules

systemctl status auditd.service
sudo service auditd restart
systemctl status auditd.service
sudo auditctl -l

echo -e "\n####################"
echo "Last Update"
echo -e "####################\n"
sudo yum check-update
sudo yum -y update

date
~~~

- work01_sv_builder_mcid1c1t.sh

~~~
# 2022/12/07 for project

#!/bin/bash

####################
# Variables
####################
SV_HOSTNAME="test-server-01"
ENV_NAME="mcid1c1t"
DOMAIN_HEAD_NAME="cid."
EKS_ENDPOINT_URL="test.com"
EFS_ID=""

declare -A OS_USERS;
OS_USERS=(
    ["sakurainaoto01c_N"]=20000
    ["sakurainaoto02c_N"]=20001
    ["sakurainaoto03c_N"]=20002
    ["mynaviapp"]=1002
)

declare -A OS_GROUPS;
OS_GROUPS=(
    ["mynaviapp"]=1002
)

####################
# Start
####################
date

echo -e "\n##############################"
echo "# OS Setup"
echo -e "##############################\n"

cd /tmp
pwd

echo -e "\n####################"
echo "HOSTNAME Setup"
echo -e "####################\n"
sudo hostnamectl set-hostname ${SV_HOSTNAME}
hostnamectl status

echo -e "\n####################"
echo "Add Users"
echo -e "####################\n"
for OS_USER in ${!OS_USERS[@]};
do
    sudo useradd -g 20000 -u ${OS_USERS[$OS_USER]} $OS_USER
    echo xxxxxxxxxxx | sudo passwd --stdin $OS_USER
done
sudo cat /etc/passwd
sudo cat /etc/shadow

echo -e "\n####################"
echo "Add Groups"
echo -e "####################\n"
for OS_GROUP in ${!OS_GROUPS[@]};
do
    sudo groupadd -g ${OS_GROUPS[$OS_GROUP]} $OS_GROUP
done
sudo cat /etc/group

echo -e "\n####################"
echo "CloudWatch Agent Setup"
echo -e "####################\n"
sudo sed -ie "s/{LOG_GROUP_ENV_NAME}/${ENV_NAME}/" /tmp/cloudwatch_agent_template.json
sudo mv /tmp/cloudwatch_agent_template.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
sudo systemctl enable amazon-cloudwatch-agent --now

echo -e "\n####################"
echo "EFS Mount Setup"
echo -e "####################\n"
# sudo yum install -y amazon-efs-utils
sudo mkdir /external
#sudo mount -t efs -o tls ${EFS_ID} /external/
df -h
sudo chmod 777 /external
sudo chown mynaviapp:mynaviapp /external
echo ${EFS_ID}':/                                   /external   efs    _netdev,noresvport,tls,iam 0 0' | sudo tee -a /etc/fstab
sudo cat /etc/fstab
#sudo umount /external
df -h
#sudo mount -fav
df -h

echo -e "\n####################"
echo "Route53 Script Setup"
echo -e "####################\n"
sudo sed -ie "s/{DOMAIN_HEAD_NAME}/${DOMAIN_HEAD_NAME}/" /tmp/update_route53_template.sh
sudo sed -ie "s/{PROFILE_ENV_NAME}/${ENV_NAME}/" /tmp/update_route53_template.sh
sudo chown root:root /tmp/update_route53_template.sh
sudo mv /tmp/update_route53_template.sh /var/lib/cloud/scripts/per-instance/update_route53.sh
sudo chmod +x /var/lib/cloud/scripts/per-instance/update_route53.sh

echo -e "\n####################"
echo "Profile Script Setup"
echo -e "####################\n"
sudo sed -ie "s/{DOMAIN_HEAD_NAME}/${DOMAIN_HEAD_NAME}/" /tmp/mcid1xxx_template.sh
sudo sed -ie "s/{EKS_ENDPOINT_URL}/${EKS_ENDPOINT_URL}/" /tmp/mcid1xxx_template.sh
sudo chown root:root /tmp/mcid1xxx_template.sh
sudo chmod 644 /tmp/mcid1xxx_template.sh
sudo mv /tmp/mcid1xxx_template.sh /etc/profile.d/${ENV_NAME}.sh

echo -e "\n####################"
echo "Last Update"
echo -e "####################\n"
sudo yum check-update
sudo yum -y update

date

~~~

- work02_sv_builder.sh

~~~
# 2022/12/07 for project

#!/bin/bash

####################
# Variables
####################
SV_HOSTNAME="test-server-01"
ENV_NAME="mcid1c1t"

declare -A OS_USERS;
OS_USERS=(
    ["sakurainaoto01c_N"]=20000
    ["sakurainaoto02c_N"]=20001
    ["sakurainaoto03c_N"]=20002
    ["mynaviapp"]=1002
)

PKGS=(
    "dos2unix"
    "nkf"
    "postgresql13-contrib"
    "redis6"
)

####################
# Start
####################
date

echo -e "\n##############################"
echo "# OS Setup"
echo -e "##############################\n"

echo -e "\n####################"
echo "HOSTNAME Setup"
echo -e "####################\n"
sudo hostnamectl set-hostname ${SV_HOSTNAME}
hostnamectl status

echo -e "\n####################"
echo "PKG Setup"
echo -e "####################\n"
for PKG in ${PKGS[@]};
do
    sudo yum install -y $PKG
done
sudo yum check-update
sudo yum -y update

echo -e "\n####################"
echo "Cloud Init Setup"
echo -e "####################\n"
echo -e '\n# This will cause the set+update hostname module to not operate (if true)\npreserve_hostname: true' | sudo tee -a /etc/cloud/cloud.cfg
sudo cat /etc/cloud/cloud.cfg | grep preserve_hostname

echo -e "\n####################"
echo "Add Users"
echo -e "####################\n"
declare -A OS_USERS;
OS_USERS=(
    ["sakurainaoto01c_N"]=20000
    ["sakurainaoto02c_N"]=20001
    ["sakurainaoto03c_N"]=20002
)
for OS_USER in ${!OS_USERS[@]};
do
    sudo useradd -g 20000 -u ${OS_USERS[$OS_USER]} $OS_USER
    echo xxxxxxxxxxx | sudo passwd --stdin $OS_USER
done
sudo cat /etc/passwd
sudo cat /etc/shadow

echo -e "\n####################"
echo "CloudWatch Agent Setup"
echo -e "####################\n"
sudo sed -ie "s/{LOG_GROUP_ENV_NAME}/${ENV_NAME}/" /tmp/cloudwatch_agent_template.json
sudo mv /tmp/cloudwatch_agent_template.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
sudo systemctl enable amazon-cloudwatch-agent --now

echo -e "\n####################"
echo "AWS Vault Setup"
echo -e "####################\n"
curl -sSL https://github.com/99designs/aws-vault/releases/download/v6.6.0/aws-vault-linux-amd64 -o ./aws-vault
chmod 755 ./aws-vault
sudo mv ./aws-vault /usr/local/bin/aws-vault
sudo chown root:root /usr/local/bin/aws-vault
aws-vault --version

date

~~~

