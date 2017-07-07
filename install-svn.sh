#!/bin/bash

Print() {

	case $3 in 
		B) 
			if [ "$1" = SL ]; then 
				echo -n -e "\e[34m$2\e[0m"
			elif [ "$1" = NL ]; then 
				echo -e "\e[34m$2\e[0m"
			else
				echo -e "\e[34m$2\e[0m"
			fi
			;;
		G)
			if [ "$1" = SL ]; then 
				echo -n -e "\e[32m$2\e[0m"
			elif [ "$1" = NL ]; then 
				echo -e "\e[32m$2\e[0m"
			else
				echo -e "\e[32m$2\e[0m"
			fi
			;;
		Y) 
			if [ "$1" = SL ]; then 
				echo -n -e "\e[33m$2\e[0m"
			elif [ "$1" = NL ]; then 
				echo -e "\e[33m$2\e[0m"
			else
				echo -e "\e[33m$2\e[0m"
			fi
			;;
		R) 
			if [ "$1" = SL ]; then 
				echo -n -e "\e[31m$2\e[0m"
			elif [ "$1" = NL ]; then 
				echo -e "\e[31m$2\e[0m"
			else
				echo -e "\e[31m$2\e[0m"
			fi
			;;

		*) 
			if [ "$1" = SL ]; then 
				echo -n -e "$2\e[0m"
			elif [ "$1" = NL ]; then 
				echo -e "$2\e[0m"
			else
				echo -e "$2\e[0m"
			fi
			;;
		esac

}


### Main Program
if [ `sestatus |grep 'SELinux status' |awk '{print $NF}'` = enabled ]; then 
	echo -e "\n\e[31mSELINUX and IPTABLES are running in system. Disable them first and run this Install\e[0m"
	echo
	echo "Run the following command to disable SELINUX and IPTABLES"
	echo -e "\t\e[35m# curl https://raw.githubusercontent.com/versionit/docs/master/vm-init.sh |bash\e[0m\n"
	exit 5
fi

if [ `id -u` -ne 0 ]; then 
	echo -e "\e[You should run this script as root user\e[0m"
	exit 4
fi

Print "SL" "=>> Checking existing configuration if any.. " "B"
rpm -q httpd &>/dev/null
pack_stat=$?
[ -f /etc/httpd/conf.d/httpd.conf ]
conf_stat=$?
[ -d /etc/httpd ]
dir_stat=$?

if [ $pack_stat -eq 0 -o $conf_stat -eq 0 -o $dir_stat -eq 0 ]; then
	rpm -e mod_dav_svn httpd &>/dev/null
	rm -rf /etc/httpd /tmp/demo /tmp/template
	[ -d /var/www/svn ] && rm -rf /var/www/svn
	Print "SL" "Present.. " "R"
	Print "NL" "Cleaned UP.. " "G"
else
	Print "SL" "No Present.. " "R"
	Print "NL" "Skipping.. " "G"
fi


Print "SL" "=>> Installing Web Server.. " "B"
yum install mod_dav_svn subversion -y &>/dev/null
if [ $? -eq 0 ] ; then
	Print "NL" "Completed.." "G"
else
	Print "NL" "Failed" "R" 
	exit 1
fi

Print "SL" "=>> Adding modules to apache configuration.. " B
echo -e "LoadModule dav_svn_module modules/mod_dav_svn.so\nLoadModule authz_svn_module modules/mod_authz_svn.so\nLoadModule dontdothat_module modules/mod_dontdothat.so" >/etc/httpd/conf.modules.d/10-subversion.conf
if [ `cat /etc/httpd/conf.modules.d/10-subversion.conf|wc -l` -eq 3 ]; then
	Print "NL" "Completed.." "G" 
else
	Print "NL" "Failed" "R" && exit 1
fi


Print "SL" "=>> Adding Subversion configuration to apache.." B
echo "<Location /svn>
DAV svn 
SVNParentPath /var/www/svn
AuthType Basic
AuthName 'Authorization Realm'
AuthUserFile /etc/svn-users
Require valid-user
</Location>" > /etc/httpd/conf.d/subversion.conf 
if [ -f /etc/httpd/conf.d/subversion.conf ]; then 
	Print "NL" "Completed.." "G" 
else
	Print "NL" "Failed" "R" && exit 1
fi

Print "NL" "=>> Creating http users for SVN.." B
Print "SL" "\t=>> Adding user - Username : tom -- Password : tom"
htpasswd -b -cm /etc/svn-users tom tom &>/dev/null
if [ $? -eq 0 ]; then 
	Print "NL" ".. Completed.." "G" 
else
	Print "NL" ".. Failed" "R" && exit 1
fi

Print "SL" "\t=>> Adding user - Username : jerry -- Password : jerry"
htpasswd -b -m /etc/svn-users jerry jerry &>/dev/null
if [ $? -eq 0 ]; then 
	Print "NL" ".. Completed.." "G" 
else
	Print "NL" ".. Failed" "R" && exit 1
fi

mkdir /var/www/svn
Print NL "=>> Creating SVN repositories" B
Print NL "\t=>> Repo Name : demo ; Repo URL : http://<PUBLIC-IP>/svn/demo" Y
cd /var/www/svn
svnadmin create demo
mkdir -p /tmp/template/{trunk,branches,tags}
svn import /tmp/template file:///var/www/svn/demo -m "Creating repository" &>/dev/null
chown -R apache:apache -R *

Print NL "\t=>> Repo Name : samnple ; Repo URL : http://<PUBLIC-IP>/svn/sample" Y
cd /var/www/svn
svnadmin create sample
mkdir -p /tmp/template/{trunk,branches,tags}
svn import /tmp/template file:///var/www/svn/sample -m "Creating repository" &>/dev/null
chown -R apache:apache -R *

Print "SL" "=>> Starting required services" B
systemctl enable httpd &>/dev/null
systemctl start httpd &>/dev/null
if [ $? -eq 0 ]; then 
	Print "NL" ".. Completed.." "G" 
else
	Print "NL" ".. Failed" "R" && exit 1
fi

cd /tmp
ip=$(ip a |grep eth0 -A 3 |grep inet |awk '{print $2}' |awk -F / '{print $1}')
Print "SL" "=>> Checking Installation.. " B
svn co http://$ip/svn/demo --username tom --password tom --non-interactive &>/dev/null
if [ $? -eq 0 ]; then 
	Print "NL" ".. Completed.." "G" 
else
	Print "NL" ".. Failed" "R" && exit 1
fi
