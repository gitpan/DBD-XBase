#!/usr/bin/perl -w

use strict;

BEGIN	{
	$| = 1;
	eval 'use DBI 1.00';
	if ($@ ne '')
		{
		print "1..0\n";
		print "DBI couldn't be loaded, aborting test\n";
		print "Error returned from eval was:\n", $@;
		print "ok 1\n";
		exit;
		}
	print "1..28\n";
	print "DBI loaded\n";
	}

END	{ print "not ok 1\n" unless $::DBIloaded; }



### DBI->trace(2);
$::DBIloaded = 1;
print "ok 1\n";

my $dir = ( -d './t' ? 't' : '.' );

print "Connect to dbi:XBase:$dir\n";
my $dbh = DBI->connect("dbi:XBase:$dir") or do
	{
	print $DBI::errstr;
	print "not ok 2\n";
	exit;
	};
print "ok 2\n";

my $command = "select ID, MSG from test";
print "Prepare command `$command'\n";
my $sth = $dbh->prepare($command) or do
	{
	print $dbh->errstr();
	print "not ok 3\n";
	exit;
	};
print "ok 3\n";

print "Execute it\n";
$sth->execute() or do
	{
	print $sth->errstr();
	print "not ok 4\n";
	exit;
	};
print "ok 4\n";

print "And get two lines\n";

my @line;

@line = $sth->fetchrow_array();
my $result = join ":", @line;
print "Got: $result\n";
print "not " if $result ne "1:Record no 1";
print "ok 5\n";

@line = $sth->fetchrow_array();
$result = join ":", @line;
print "Got: $result\n";
print "not " if $result ne "3:Message no 3";
print "ok 6\n";

@line = $sth->fetchrow_array();
print "Got empty list\n" unless @line;
print "not " if scalar(@line) != 0;
print "ok 7\n";

$sth->finish();


$command = "select * from rooms where facility = 'Audio' or roomname > 'B'";
print "Prepare command `$command'\n";
$sth = $dbh->prepare($command) or do
	{
	print $dbh->errstr();
	print "not ok 8\n";
	exit;
	};
print "ok 8\n";

print "Execute it\n";
$sth->execute() or do
	{
	print $sth->errstr();
	print "not ok 9\n";
	exit;
	};
print "ok 9\n";

print "And now get the result\n";

$result = '';
while (@line = $sth->fetchrow_array())
	{ $result .= "@line\n"; }


my $expected_result = '';

while (<DATA>)
	{
	last if /^__END_DATA__$/;
	$expected_result .= $_;
	}

if ($result ne $expected_result)
	{
	print "Expected:\n$expected_result";
	print "Got:\n$result";
	print "not ";
	}
print "ok 10\n";


$command = "select * from rooms where facility = ? or roomname > ?";
print "Prepare command `$command'\n";
$sth = $dbh->prepare($command) or do
	{
	print $dbh->errstr();
	print "not ok 11\n";
	exit;
	};
print "ok 11\n";

print "Execute it with bind parameters ('Audio', 'B')\n";
$sth->execute('Audio', 'B') or do
	{
	print $sth->errstr();
	print "not ok 12\n";
	exit;
	};
print "ok 12\n";

print "And now get the result\n";

$result = '';
while (@line = $sth->fetchrow_array())
	{ $result .= "@line\n"; }


if ($result ne $expected_result)
	{
	print "Expected:\n$expected_result";
	print "Got:\n$result";
	print "not ";
	}
print "ok 13\n";

$command = "select facility,roomname from rooms where roomname > ? or facility = ? order by roomname";
print "Prepare command\t`$command'\n";
$sth = $dbh->prepare($command) or do
	{
	print $dbh->errstr();
	print "not ok 14\n";
	exit;
	};
print "ok 14\n";

print "Execute it with bind parameters ('F', 'Audio')\n";
$sth->execute('F', 'Audio') or do
	{
	print $sth->errstr();
	print "not ok 15\n";
	exit;
	};
print "ok 15\n";


print "And now get the result\n";

$result = '';
while (@line = $sth->fetchrow_array())
	{ $result .= "@line\n"; }

$expected_result = '';
while (<DATA>)
	{
	last if /^__END_DATA__$/;
	$expected_result .= $_;
	}

if ($result ne $expected_result)
	{
	print "Expected:\n$expected_result";
	print "Got:\n$result";
	print "not ";
	}
print "ok 16\n";


$command = 'select * from rooms where roomname like ?';
print "Prepare $command\n";
$sth = $dbh->prepare($command) or do {
	print $dbh->errstr, "not ok 17\n";
	exit;
	};
print "ok 17\n";

print "Execute it with parameter '%f%'\n";
$sth->execute('%f%') or do {
	print $dbh->errstr, "not ok 18\n";
	exit;
	};
print "ok 18\n";

print "And now get the result\n";
$result = '';
while (@line = $sth->fetchrow_array())
	{ $result .= "@line\n"; }
$expected_result = '';
while (<DATA>)
	{
	last if /^__END_DATA__$/;
	$expected_result .= $_;
	}

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 19\n";


$command = 'select * from rooms where facility like ? and roomname not like ?';
print "Prepare $command\n";
$sth = $dbh->prepare($command) or do {
	print $dbh->errstr, "not ok 20\n";
	exit;
	};
print "ok 20\n";

print "Execute it with parameters '%o', 'mi%'\n";
$sth->execute('%o', 'mi%') or do {
	print $dbh->errstr, "not ok 21\n";
	exit;
	};
print "ok 21\n";

print "And now get the result\n";
$result = '';
while (@line = $sth->fetchrow_array())
	{ $result .= "@line\n"; }
$expected_result = '';
while (<DATA>)
	{
	last if /^__END_DATA__$/;
	$expected_result .= $_;
	}

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 22\n";


$command = 'select facility, roomname from rooms where (facility = :fac or
		facility = :fac1) and roomname not like :name';
print "Prepare $command\n";
$sth = $dbh->prepare($command) or do {
	print $dbh->errstr, "not ok 23\n";
	exit;
	};
print "ok 23\n";

print "Bind named parameters: Film, Main, Bay%\n";
$sth->bind_param(':fac', 'Film');
$sth->bind_param(':fac1', 'Main');
$sth->bind_param(':name', 'Bay%');

$sth->execute or do {
	print $dbh->errstr, "not ok 24\n";
	exit;
	};
print "ok 24\n";

print "And now get the result\n";
$result = '';
while (@line = $sth->fetchrow_array())
	{ $result .= "@line\n"; }
$expected_result = '';
while (<DATA>)
	{
	last if /^__END_DATA__$/;
	$expected_result .= $_;
	}

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 25\n";


$command = 'select facility, roomname from rooms where roomname like :bay
	or facility = :film';
print "Prepare $command\n";
$sth = $dbh->prepare($command) or do {
	print $dbh->errstr, "not ok 26\n";
	exit;
	};
print "ok 26\n";

print "Bind named parameters in execute call\n";
$sth->execute('Bay  _', 'Film') or do {
	print $dbh->errstr, "not ok 27\n";
	exit;
	};
print "ok 27\n";

print "And now get the result\n";
$result = '';
while (@line = $sth->fetchrow_array())
	{ $result .= "@line\n"; }
$expected_result = '';
while (<DATA>)
	{
	last if /^__END_DATA__$/;
	$expected_result .= $_;
	}

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 28\n";







$sth->finish();
$dbh->disconnect();

1;

__DATA__
Bay  1 Main
Bay 14 Main
Bay  2 Main
Bay  5 Main
Bay 11 Main
Bay  6 Main
Bay  3 Main
Bay  4 Main
Bay 10 Main
Bay  8 Main
Gigapix Main
Bay 12 Main
Bay 15 Main
Bay 16 Main
Bay 17 Main
Bay 18 Main
Mix A Audio
Mix B Audio
Mix C Audio
Mix D Audio
Mix E Audio
ADR-Foley Audio
Mach Rm Audio
Transfer Audio
Bay 19 Main
Dub Main
Flambe Audio
FILM 1 Film
FILM 2 Film
FILM 3 Film
SCANNING Film
Mix F Audio
Mix G Audio
Mix H Audio
BullPen Film
Celco Film
MacGrfx Main
Mix J Audio
BAY 7 Main
__END_DATA__
Audio ADR-Foley
Film FILM 1
Film FILM 2
Film FILM 3
Audio Flambe
Main Gigapix
Main MacGrfx
Audio Mach Rm
Audio Mix A
Audio Mix B
Audio Mix C
Audio Mix D
Audio Mix E
Audio Mix F
Audio Mix G
Audio Mix H
Audio Mix J
Film SCANNING
Audio Transfer
__END_DATA__
ADR-Foley Audio
Transfer Audio
Flambe Audio
FILM 1 Film
FILM 2 Film
FILM 3 Film
Mix F Audio
MacGrfx Main
__END_DATA__
ADR-Foley Audio
Mach Rm Audio
Transfer Audio
Flambe Audio
__END_DATA__
Main Gigapix
Main Dub
Film FILM 1
Film FILM 2
Film FILM 3
Film SCANNING
Film BullPen
Film Celco
Main MacGrfx
Main AVID
__END_DATA__
Main Bay  1
Main Bay  2
Main Bay  5
Main Bay  6
Main Bay  3
Main Bay  4
Main Bay  8
Film FILM 1
Film FILM 2
Film FILM 3
Film SCANNING
Film BullPen
Film Celco
