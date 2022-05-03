#!/usr/bin/perl

# Based on check_memory.pl by Jason Hancock
# see https://github.com/jasonhancock/nagios-memory

use strict;
use warnings;

use Data::Dumper qw/Dumper/;

my $mpModule = 'Monitoring::Plugin';
eval("use $mpModule");
if ($@) {
  $mpModule = 'Nagios::Plugin';
  eval("use $mpModule");
}

my $mp = $mpModule->new(
    usage     => "Usage: %s",
    shortname => '/proc/meminfo',
);

# read the data from /proc/meminfo into the %data hash
my %data;
open IN, '</proc/meminfo' or np->nagios_exit('UNKNOWN', 'Can\'t read /proc/meminfo');
while(my $line=<IN>) {
    if($line=~m/^(.+):\s+(\d+)/) {
        $data{$1} = $2;
    }
}
close IN;

my $value;
for my $item (sort keys %data){
	$value = $data{$item};
	$mp->add_perfdata(
		label => $item,
		value => sprintf("%d", $value / 1024),
		uom   => "MB",
	);
};

$mp->nagios_exit('OK', "");

