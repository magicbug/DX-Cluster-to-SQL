#!/usr/bin/perl 

use Net::Telnet ();
use DBI;
use POSIX (strftime);

$dbh = DBI->connect("DBI:mysql:database;host=localhost",'username','password')
        or die "Could not connect to MySQL database: " . DBI->errstr;

$t = new Net::Telnet (Timeout => 30, Port => 8000, Prompt => '/./');
$t->open("gb7mbc.net");
@lines = $t->cmd("callsign");
print @lines;

while (1)  {
 %spot = ();
 $line = $t->getline(Timeout => 300);
 next unless ($line =~ /^DX/);

 $spot{call} = substr($line, 6, 10);
 $spot{call} =~ s/[^a-z0-9\/]//gi;
 $spot{freq} = substr($line, 16, 8);
 $spot{freq} =~ s/[^0-9\.]//g;
 $spot{dxcall} = substr($line, 26, 12);
 $spot{dxcall} =~ s/[^a-z0-9\/]//gi;
 $spot{comment} = substr($line, 39, 30);
 $spot{comment} =~ s/\s+$//g;
 $spot{comment} = $dbh->quote($spot{comment});
 $spot{utc} = substr($line, 70, 4);

 $spot{band} = &freq2band($spot{freq});

### The statement handle
my $sth = $dbh->prepare( "SELECT * FROM dxcc WHERE prefix = SUBSTRING('$spot{dxcall}', 1, LENGTH(prefix)) ORDER BY LENGTH( prefix ) DESC LIMIT 1 " );

$sth->execute();

while ( @row = $sth->fetchrow_array ) {
    $dx{prefix} =$row[0];
	$dx{name} = $row[1];
	$dx{cqz} = $row[2];
	$dx{ituz} = $row[3];
	$dx{cont} = $row[4];
	$dx{long} = $row[5];
	$dx{lat}  = $row[6];

}

### The statement handle
my $sth2 = $dbh->prepare( "SELECT * FROM dxcc WHERE prefix = SUBSTRING('$spot{call}', 1, LENGTH(prefix)) ORDER BY LENGTH( prefix ) DESC LIMIT 1 " );

$sth2->execute();

while ( @row = $sth2->fetchrow_array ) {
%spotter = ();
	$spotter{prefix} =$row[0];
	$spotter{name} = $row[1];
	$spotter{cqz }= $row[2];
	$spotter{ituz} = $row[3];
	$spotter{cont} = $row[4];
	$spotter{long} = $row[5];
	$spotter{lat}  = $row[6];
}


 # Assemble time string from utc in spot + UTC date
 my ($day, $month, $year) = (gmtime(time))[3,4,5];
 $month = sprintf("%02d", $month+1);
 $day = sprintf("%02d", $day);
 $year += 1900;
 $time = "$year-$month-$day ".substr($spot{utc}, 0, 2).":".substr($spot{utc},
		 2, 2).":00";

$dbh->do("INSERT INTO spots 
		 (`call`, `freq`, `dxcall`, `comment`, `time`, `band`, 
		 `dx_prefix`, `dx_name`, `dx_cqz`, `dx_ituz`, `dx_cont`, `dx_long`, `dx_lat`,
		 `spotter_prefix`, `spotter_name`, `spotter_cqz`, `spotter_ituz`, `spotter_cont`, `spotter_long`, `spotter_lat`) VALUES 
		 ('$spot{call}', '$spot{freq}', '$spot{dxcall}', $spot{comment},
		 '$time', '$spot{band}', '$dx{prefix}', '$dx{name}', '$dx{cqz}', '$dx{ituz}', '$dx{cont}', '$dx{long}', '$dx{lat}', '$spotter{prefix}', '$spotter{name}', '$spotter{cqz}', '$spotter{ituz}', '$spotter{cont}', '$spotter{long}', '$spotter{lat}');");

 foreach (sort keys %spot) {
	print "$_ -> >$spot{$_}<\n"
 }
 print "----------\n";

}

sub freq2band {
		my $freq = shift;

		if (($freq >= 135) && ($freq <= 138)) { $freq = "2190"; }
		elsif (($freq >= 1800) && ($freq <= 2000)) { $freq = "160"; }
		elsif (($freq >= 3500) && ($freq <= 4000)) { $freq = "80"; }
		elsif (($freq >= 7000) && ($freq <= 7300)) { $freq = "40"; }
		elsif (($freq >=10100) && ($freq <=10150)) { $freq = "30"; }
		elsif (($freq >=14000) && ($freq <=14350)) { $freq = "20"; }
		elsif (($freq >=18068) && ($freq <=18168)) { $freq = "17"; }
		elsif (($freq >=21000) && ($freq <=21450)) { $freq = "15"; }
		elsif (($freq >=24890) && ($freq <=24990)) { $freq = "12"; }
		elsif (($freq >=28000) && ($freq <=29700)) { $freq = "10"; }
		elsif (($freq >=50000) && ($freq <=54000)) { $freq = "6"; }
		elsif (($freq >=70000) && ($freq <=71000)) { $freq = "4"; }
		elsif (($freq >=144000) && ($freq <=148000)) { $freq = "2"; }
		elsif (($freq >=430000) && ($freq <=460000)) { $freq = "07"; }
		elsif (($freq >=1200000) && ($freq <=1300000)) { $freq = "023"; }
		else {
			$freq = 0;
		}

		return $freq;

}


