#!/usr/bin/perl
use DBI;
use Data::Dumper;
use Net::SNMP; 
use Config::IniFiles;
use FindBin '$Bin';
my $cfg = Config::IniFiles->new( -file => "$Bin/../db.conf");
my $driver = "mysql"; 
my $ip_data= $cfg->val( 'ip_data', 'IP' );;
my $database = $cfg->val( 'Database', 'DBname' ); 
my $port = $cfg->val( 'ip_data', 'Port' );
my $dsn = "DBI:$driver:database=$database;host=$ip_data;port=$port";
#my $directory = $cfg->val( 'ip_data', 'ServerDirectory' );
my $device= $cfg->val( 'Database', 'Tablename' ); 
my $userid = $cfg->val( 'Database', 'Username' ); # user ID 
my $password = $cfg->val( 'Database', 'Password' ); # password
print ("Creating PHP files ");
$x="index";
open(my $fth, '>', "$Bin/$x.php");
print $fth "<html><meta http-equiv=\"refresh\" content=\"10\"> <?php \$con=mysqli_connect(\"$ip_data\",\"$userid\",\"$password\",\"$database\",\"$port\");
\$result = mysqli_query(\$con,\"SELECT * FROM lab5\"); 
echo \"<table border='10'>
<tr>
<th> ID </th>
<th>IP</th>
<th>Community</th>
<th>Color</th>
</tr>\";
while(\$row = mysqli_fetch_array(\$result))
{echo \"<tr>\";
  echo \"<td>\" . \$row['ID'] . \"</td>\";
  echo \"<td><a href=\\\"redirect.php?IP=\".\$row['IP'].\"&Community=\".\$row['Community']. \"\\\">\". \$row['IP'] . \"</a></td>\";
  echo \"<td>\" . \$row['Community'] . \"</td>\";
  echo \"<td bgcolor=\".\$row['Color'].\" </td>\";
 echo \"</tr>\";
  }echo \"</table>\";
?> 
</html>
";
close $fth;
print "done creating index.php\n";
$x="redirect";
open(my $fth2, '>', "$Bin/$x.php");
print $fth2 "<html><meta http-equiv=\"refresh\" content=\"10\"> <?php
\$IP=\$_GET['IP'];
\$Community=\$_GET['Community'];  \$con=mysqli_connect(\"$ip_data\",\"$userid\",\"$password\",\"$database\");\$Que=\"SELECT IP, Community, Lastreportedtime,totalsent,totallost,updated_at  FROM lab5 where IP=\\\"\$IP\\\" AND Community=\\\"\$Community\\\"\" ;
\$result = mysqli_query(\$con,\$Que);
echo \"<table border='10'>
<tr>
<th>IP</th>
<th>Community</th>
<th>Last Reported Time</th>
<th>Total Number of Request's sent</th>
<th>Total Number of Unanswered Request's</th>
<th>Last update time</th>
</tr>\";
while(\$row = mysqli_fetch_array(\$result))
{echo \"<tr>\";
 echo \"<td>\" . \$row['IP'] . \"</td>\";
  echo \"<td>\" . \$row['Community'] . \"</td>\";
  echo \"<td>\" . \$row['Lastreportedtime'] . \"</td>\";
echo \"<td>\" . \$row['totalsent'] . \"</td>\";
echo \"<td>\" . \$row['totallost'] . \"</td>\";
echo \"<td>\" . \$row['updated_at'] . \"</td>\";
 echo \"</tr>\";
}  
echo \"</table>\";
\$date = date('Y-m-d H:i:s');
echo \"local PC time\".\$date;
?> 
</html>";
close $fth2;
print ("Done creating redirect.php");
my $dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
my $sth = $dbh->prepare("CREATE TABLE IF NOT EXISTS `lab5` (
  `ID` int(11) NOT NULL,
  `IP` tinytext NOT NULL,
  `PORT` tinytext NOT NULL,
  `Community` tinytext NOT NULL,
  `Color` tinytext NOT NULL,
  `Lastreportedtime` tinytext NOT NULL,
  `totalsent` int(11) NOT NULL DEFAULT '0',
  `totallost` int(11) NOT NULL DEFAULT '0',
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
                     ON UPDATE CURRENT_TIMESTAMP,  
  PRIMARY KEY (`ID`)) ENGINE=InnoDB  DEFAULT CHARSET=latin1");
$sth->execute() or die $DBI::errstr;
my $kth= $dbh->prepare("INSERT INTO lab5 (ID,IP,PORT,Community) SELECT id, IP,PORT,COMMUNITY FROM $device ON DUPLICATE KEY UPDATE ID=$device.id, IP=$device.IP, PORT=$device.PORT, Community=$device.COMMUNITY"); 
#my $kth= $dbh->prepare("INSERT INTO lab5 (ID,IP,PORT,Community) SELECT id, IP,PORT,COMMUNITY FROM $device ON DUPLICATE KEY UPDATE ID=$device.id, IP=$device.IP, PORT=$device.PORT, Community=$device.COMMUNITY, Color='' , Lastreportedtime='' ,totalsent='' ,totallost='' ,updated_at='' "); 
$kth->execute() or die $DBI::errstr;
my $sysUpTime = '1.3.6.1.2.1.1.3.0';
my $sth = $dbh->prepare("select ID,IP,PORT,COMMUNITY from lab5");
$sth->execute() or die $DBI::errstr;
my @id=();
my @IP_data=();
my @port=();
my @community=();
while (my @element = $sth->fetchrow_array()){
#print Dumper(@element);
push(@id,$element[0]);
push(@IP_data,$element[1]);
push(@port,$element[2]);
push(@community,$element[3]);
}
our @request_lost;
our @request_cm;
our @request_sent;
foreach my $c (0..$#IP_data)
{
push(@request_lost,0);
push(@request_cm,0);
push(@request_sent,0);
}

while(1) {
my $start = time();
print "\nstart time for 150 devices".$start."\n";
foreach $host (0..$#IP_data) {
      my ($session, $error) = Net::SNMP->session(
         -hostname    => $IP_data[$host],
         -port        => $port[$host],
         -community   => $community[$host],
         -nonblocking => 1,
         -timeout     => 1,
         
      );
#print (Dumper($session));
 if (!defined $session) {
         printf "ERROR: Failed to create session for host '%s': %s.\n",
                $IP_data[$host], $error;
         next;
      }

      my $result = $session->get_request(
         -varbindlist => [ $sysUpTime ],
         -callback    => [ \&get_callback, $IP_data[$host], $port[$host],$host],
      );
#print "$request_sent[$host] sent \n";
#print "$port[$host]\n port number";
if (!defined $result) {
         printf "ERROR: Failed to queue get request for host '%s': %s.\n",
                $session->hostname(), $session->error();
      }

    
}


   # Now initiate the SNMP message exchange.

snmp_dispatcher();
my $endtime = time();
#print "\nend time for 150 devices".$endtime."\n";
my $time = $endtime - $start;
#print "\ntime taken to send 150 requests/responses for 150 devices ".$time."\n";
my $sleep_time =30-$time;

    sleep $sleep_time;}
   exit 0;
sub get_callback
   {

      my ($session, $IP,$port, $request) = @_;  
my $color;  
     $request_sent[$request]=$request_sent[$request]+1;
     my $result = $session->var_bind_list();
      if (!defined $result) {
   $request_lost[$request]=  $request_lost[$request]+1;
  print "\nCumulative Misses $request_cm[$request]  ,$IP\n";
  $request_cm[$request]=$request_cm[$request]+1;
        }
else{
      $request_cm[$request]=0;
      }
my $commu=$session->security->community;
     
if ($request_cm[$request]>=29){
   $request_cm[$request]=28;
    }
	$color=sprintf("%x",255-($request_cm[$request]*8)) x 2;
$color=uc($color);
$color='#FF'.$color;
print "\ncolor $color\n";
if($result->{$sysUpTime}!=''){
 my $cth= $dbh->prepare("update lab5 set Color=\'$color\', Lastreportedtime=\'$result->{$sysUpTime}\', totalsent=\'$request_sent[$request]\', totallost=\'$request_lost[$request]\' where IP=\'$IP\' AND Community=\'$commu\'AND Port=\'$port\'");
$cth->execute() or die $DBI::errstr;}
else
{
my $cth= $dbh->prepare("update lab5 set Color=\'$color\', totalsent=\'$request_sent[$request]\', totallost=\'$request_lost[$request]\' where IP=\'$IP\' AND Community=\'$commu\'AND Port=\'$port\'");
$cth->execute() or die $DBI::errstr;}
}
my $date2=`date +%s`;
my $ID=$request+1;
#print "\nresponse time  of". $ID ."is".$date2."\n";

