1) Install Tomcat (Source)

2) Downlaod the jar file in lib directory   <tomcatc source>/lib

	wget https://github.com/versionit/customwebapp/blob/master/mysql-connector-java-5.1.40.jar?raw=true -O mysql-connector-java-5.1.40.jar
	
  Download student.war file in webapps directory <tomcat source>/webapps
        wget https://github.com/versionit/customwebapp/blob/master/student.war?raw=true -O student.war

3) Update <tomcat source>/conf/context.xml 

	{add the following content in context.xml just before the last line}

<Resource name="jdbc/TestDB" auth="Container" type="javax.sql.DataSource"
               maxTotal="100" maxIdle="30" maxWaitMillis="10000"
               username="root" password="root" driverClassName="com.mysql.jdbc.Driver"
               url="jdbc:mysql://localhost:3306/test"/>

4) yum install mariadb mariadb-server -y

5) Set the root password

	# systemctl start mariadb 
	# mysql -u root

		mysql> use mysql;
		mysql> UPDATE user SET password=PASSWORD("root") WHERE User='root';
		mysql> FLUSH PRIVILEGES;
		mysql>  quit
	# systemctl restart mariadb

6) create Students table

	# mysql -u root -p

	mysql> create database test;
	mysql> use test;

	<<< copy and paste the below query >>>


CREATE TABLE Students(student_id INT NOT NULL AUTO_INCREMENT,
	student_name VARCHAR(100) NOT NULL,
    student_addr VARCHAR(100) NOT NULL,
	student_age VARCHAR(3) NOT NULL,
	student_qual VARCHAR(20) NOT NULL,
	student_percent VARCHAR(10) NOT NULL,
	student_year_passed VARCHAR(10) NOT NULL,
	PRIMARY KEY (student_id)
);



7) Start the tomcat and download the war file from https://github.com/versionit/customwebapp  and check on browser
