# How to configure a YUM repository

Tested on CentOS Linux 7

## Requirements
CentOS Linux 7 where the YUM repository will be created and configured (SERVER).

CentOS Linux 7 where YUM will be configured to install packages from the previously configured repository (CLIENT).

## On the repository machine:

Make a directory containing all rpm files you want to share, in this example it will be /mnt/local_repo 
Create a local YUM repository
```bash
#run as root
yum install createrepo
createrepo /mnt/local_repo/
#Your local YUM repository is ready.
```
Add your local repo to the list
```bash
#run as root
cd /etc/yum.repos.d/
touch local_repository.repo
```
Add the following into local_repository.repo
```bash
[localrepo]
name=CentOS Core $releasever - My Local Repo
baseurl=file:///mnt/local_repo/
enabled=1
gpgcheck=0
```
Let's make our local repository available for the client side.
```bash
yum install httpd
cd /var/www/html/
mkdir repo
cp -r /mnt/local_repo/ /var/www/html/repo/
#Now you can access your packages from an internet browser with http://<YOUR-SERVER-IP>/repo/local_repo/
```
Client side configuration
```bash
vi /etc/yum.repos.d/localrepo.repo
```
Add the following content:
```bash
[localrepo]
name=Unixmen Repository
baseurl=http://<YOUR-SERVER-IP>/repo/local_repo/
gpgcheck=0
enabled=1
```
You can now verify if your repository is in the YUM repo list
```bash
yum repolist
```
