# Install web server
```
# yum install httpd -y
```

# Start a web server 
```
# systemctl enable httpd
# systemctl start httpd
```

# How to host a web sites.
```
# cd /var/www/html
# mkdir demo
# cd demo
# vim index.html
Hello World, Welcome to my web server
:wq!
#
```

# Access the web site over browser by hitting `External IP Addrress` of server in browser.
### URL : `http://<IP-ADDRESS>/demo`
