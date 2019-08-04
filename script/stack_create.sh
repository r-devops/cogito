#!/bin/bash

### Color Variables
Y="\e[33m"
R="\e[31m"
G="\e[32m"
B="\e[34m"
C="\e[36m"
N="\e[0m"

### Variables
URL="http://redrockdigimark.com/apachemirror/tomcat/tomcat-9/v9.0.0.M22/bin/apache-tomcat-9.0.0.M22.tar.gz"
TAR_FILE_NAME=$(echo $URL |awk -F / '{print $NF}')
TAR_DIR=$(echo $TAR_FILE_NAME|sed -e 's/.tar.gz//')

MODJK_URL="http://redrockdigimark.com/apachemirror/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.42-src.tar.gz"
MODJK_TAR_FILE_NAME=$(echo $MODJK_URL |awk -F / '{print $NF}')
MODJK_TAR_DIR=$(echo $MODJK_TAR_FILE_NAME | sed -e 's/.tar.gz//')


### Root user check
ID=`id -u`
if [ $ID -ne 0 ]; then
	echo -e "$R You should be root user to perform this command $N"
	echo -e "$Y If you have sudo access then run the script with sudo command $N"
	exit 1
fi
#### Installation of WEb Server
echo -n -e "$Y Installing Web Server..$N"
yum install httpd httpd-devel -y &>/dev/null
if [ $? -eq 0 ]; then
	echo -e "$G SUCCESS $N"
else
	echo -e "$R FAILURE $N"
fi


### Tomcat Instaallation
echo -n -e "$Y Downloading Tomcat .. $N"
yum install java -y &>/dev/null
wget $URL -O /tmp/$TAR_FILE_NAME &>/dev/null
tar tf /tmp/$TAR_FILE_NAME &>/dev/null
if [ $? -eq 0 ]; then
        echo -e "$G SUCCESS $N"
else
        echo -e "$R FAILURE $N"
fi

if [ -d /opt/tomcat ]; then 
	rm -rf /opt/tomcat
fi

echo -n -e "$Y Extracting Tomcat .. $N"
cd /opt
tar xf /tmp/$TAR_FILE_NAME 
mv $TAR_DIR tomcat
if [ -d /opt/tomcat ]; then 
	echo -e "$G SUCCESS $N"
else
        echo -e "$R FAILURE $N"
fi

### DB Installation
echo -n -e "$Y Installing Database .. $N"
yum install mariadb mariadb-server -y &>/dev/null
if [ $? -eq 0 ]; then 
        echo -e "$G SUCCESS $N"
else
        echo -e "$R FAILURE $N"
fi

systemctl start mariadb
systemctl enable mariadb &>/dev/null

#### Setting up DB 
echo -n -e "$B Configuring DB .. $N"
mysql -e 'use studentapp' &>/dev/null
if [ $? -eq 0 ]; then 
	echo -e "$C Skipping $N"
else

mysql <<EOF
create database studentapp;
use studentapp;
CREATE TABLE Students(student_id INT NOT NULL AUTO_INCREMENT,
	student_name VARCHAR(100) NOT NULL,
    student_addr VARCHAR(100) NOT NULL,
	student_age VARCHAR(3) NOT NULL,
	student_qual VARCHAR(20) NOT NULL,
	student_percent VARCHAR(10) NOT NULL,
	student_year_passed VARCHAR(10) NOT NULL,
	PRIMARY KEY (student_id)
);
grant all privileges on studentapp.* to 'student'@'10.128.0.5' identified by 'student@1';
EOF
echo -e "$G SUCCESS $N"
fi

### Configuring Tomcat
echo -n -e "$B Configuring Tomcat .. $N"
wget -O /opt/tomcat/lib/mysql-connector-java-5.1.40.jar https://github.com/carreerit/cogito/raw/master/appstack/mysql-connector-java-5.1.40.jar &>/dev/null
rm -rf /opt/tomcat/webapps/*
wget -O /opt/tomcat/webapps/student.war https://github.com/carreerit/cogito/raw/master/appstack/student.war &>/dev/null
sed -i -e '$ i <Resource name="jdbc/TestDB" auth="Container" type="javax.sql.DataSource" maxTotal="100" maxIdle="30" maxWaitMillis="10000" username="student" password="student@1" driverClassName="com.mysql.jdbc.Driver" url="jdbc:mysql://localhost:3306/studentapp"/>' /opt/tomcat/conf/context.xml
grep TestDB /opt/tomcat/conf/context.xml &>/dev/null
STAT=$?
if [ -f /opt/tomcat/lib/mysql-connector-java-5.1.40.jar -a -f /opt/tomcat/webapps/student.war -a $STAT -eq 0 ];then
       echo -e "$G SUCCESS $N"
else
        echo -e "$R FAILURE $N"
fi

### Configuring Web Server
echo -n -e "$B Configuring Mod_JK .. $N"
yum install httpd-devel gcc -y &>/dev//null
wget $MODJK_URL -O /opt/$MODJK_TAR_FILE_NAME &>/dev/null
cd /opt
tar xf $MODJK_TAR_FILE_NAME
cd $MODJK_TAR_DIR/native
./configure --with-apxs=/bin/apxs &>/dev/null
make &>/dev/null
make install &>/dev/null
echo 'LoadModule jk_module modules/mod_jk.so
JkWorkersFile conf.d/workers.properties
JkLogFile logs/mod_jk.log
JkLogLevel info
JkLogStampFormat "[%a %b %d %H:%M:%S %Y]"
JkOptions +ForwardKeySize +ForwardURICompat -ForwardDirectories
JkRequestLogFormat "%w %V %T"
JkMount /student tomcatA
JkMount /student/* tomcatA' >/etc/httpd/conf.d/mod_jk.conf

echo '### Define workers
worker.list=tomcatA
### Set properties
worker.tomcatA.type=ajp13
worker.tomcatA.host=localhost
worker.tomcatA.port=8009' >/etc/httpd/conf.d/workers.properties

systemctl restart httpd 
if [ $? -eq 0 ] ; then 
	echo -e "$G SUCCESS $N"
else
	echo -e "$R FAILURE $N"
fi


### Restart Services
echo -n -e "$C Restarting Mariadb .. "
systemctl restart mariadb &>/dev/null
if [ $? -eq 0 ]; then
	echo -e "$G SUCCESS $N"
else
	echo -e "$R FAILURE $N"
fi

echo -n -e "$C Restarting TOmcat .. "
pkill -9 java &>/dev/null
/opt/tomcat/bin/startup.sh &>/dev/null
if [ $? -eq 0 ]; then
        echo -e "$G SUCCESS $N"
else
        echo -e "$R FAILURE $N"
fi
echo -n -e "$C Restarting Web Server .. "
systemctl restart httpd &>/dev/null
if [ $? -eq 0 ]; then
        echo -e "$G SUCCESS $N"
else
        echo -e "$R FAILURE $N"
fi

















