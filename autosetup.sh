#!/bin/sh
echo Development tools install
yum -y groupinstall base "Development tools"

echo Apache install
yum install -y httpd httpd-devel
systemctl start httpd
systemctl enable httpd

echo firewall allow
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

echo Python install 
yum install -y https://centos7.iuscommunity.org/ius-release.rpm
yum install -y python36u python36u-libs python36u-devel python36u-pip
pip3.6 install virtualenv
pip3.6 install --upgrade pip

echo make virtualenv
mkdir /opt/project
cd /opt/project
virtualenv env
chmod 755 /opt/project/env
cd env
source bin/activate
pip install django
pip install mod_wsgi

echo copy mod_wsgi configure file
mkdir /etc/httpd/conf.d/modules
cp /opt/project/env/lib/python3.6/site-packages/mod_wsgi/server/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so /etc/httpd/conf.d/modules/

echo > /etc/httpd/conf.modules.d/mod_wsgi.conf
sed -i -e "$ i LoadModule wsgi_module \/etc\/httpd\/conf.d\/modules\/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so" /etc/httpd/conf.modules.d/mod_wsgi.conf


echo  create django project
django-admin startproject webapp

sed -i.bak -e "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \[\'*\'\]/" webapp/webapp/settings.py

# django.conf 作成
echo > /etc/httpd/conf.d/django.conf
sed -i -e "$ i WSGIScriptAlias \/ \/opt/project\/env\/webapp\/webapp\/wsgi.py" /etc/httpd/conf.d/django.conf
sed -i -e "$ i WSGIPythonPath \/opt\/project\/env\/webapp" /etc/httpd/conf.d/django.conf
sed -i -e "$ i WSGIPythonHome \/opt\/project\/env" /etc/httpd/conf.d/django.conf
sed -i -e "$ i <Directory \/opt\/project\/env\/webapp>" /etc/httpd/conf.d/django.conf
sed -i -e "$ i <Files wsgi.py>" /etc/httpd/conf.d/django.conf
sed -i -e "$ i Require all granted" /etc/httpd/conf.d/django.conf
sed -i -e "$ i <\/Files>" /etc/httpd/conf.d/django.conf
sed -i -e "$ i <\/Directory>" /etc/httpd/conf.d/django.conf

# httpd 再起動
systemctl restart httpd
