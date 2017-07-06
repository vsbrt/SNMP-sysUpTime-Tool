# SNMP-sysUpTime-Tool
A tool that probes sysUpTime of SNMP devices stored in a database table and represent their running status on a web GUI.

# Dependencies Required: 

* Perl Module Net::SNMP
* Perl Module Config::IniFiles
* Linux Lamp Stack which includes PHP, MySQL, Apache in one package.
* For installing the Lampstack, Enter the following command in the terminal:
	* sudo apt-get install lamp-server^

# EXECUTION OF THE SCRIPT:

1. Change the database the creditials in db.conf in et2536-save15/ Folder.
2. Change the permissions of apache directory /var/www by the entering the following command:
	"sudo chmod -R 777 /var/www to avoid problems"
3. Run perl script backend.pl using the command:
	"perl backend.pl" 
4. Don't the exit the running terminal or send to background process.
5. User should go to the webpage for monitoring the status of the devices.
  	URL: http://localhost/et2536-save15/assignment4/index.php


NOTE: Index.php and redirect.php are created only when backend.pl script is executed.
