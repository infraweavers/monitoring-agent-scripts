#!/usr/bin/perl

use strict;
use warnings;
use Monitoring::Plugin;

my $mp = Monitoring::Plugin->new(
    usage     => "Usage: %s\n",
    version   => '0.0.1',
    plugin    => $0,
    shortname => 'Container status',
    blurb     => 'Are containers correctly configured',
    timeout   => 10,
);

$mp->getopts;

my $containers = qx/sudo lxc-ls -1 | sort -u/;
my @problems;

my @cons = split('\n', $containers);
for my $container (@cons) {

    my $containermemusage;
    my $containertxbytes;
    my $containerrxbytes;
    my $containerio;

    my $containerrunning = qx/sudo lxc-ls --filter=$container --fancy --fancy-format state,autostart --active/;

    if ($containerrunning eq '') { 
        push(@problems, $container . ' Stopped, ');
        next;
    } 

    open (my $cpufh, '<:encoding(UTF-8)', "/sys/fs/cgroup/cpuacct/lxc/$container/cpuacct.stat");
    while (my $cpujiffies = <$cpufh>) {
        my @cpuinfodata = split(/ /, $cpujiffies) ;
        my $label = $cpuinfodata[0];
        my $value = $cpuinfodata[1];
        chomp($value);
        $mp->add_perfdata(
            label => $container . " CPU " . $label,
            uom => "c",
            value => $value
        )
    }
    close($cpufh);

    open (my $memfh, '<:encoding(UTF-8)', "/sys/fs/cgroup/memory/lxc/$container/memory.limit_in_bytes");
    my $containermemlimit = <$memfh>;
    chomp($containermemlimit);
    close($memfh);

    if ($containermemlimit >= 1000000000000) { # 1 TB
        push(@problems, $container . ' No memory limit, ');
    }

    my @lxcinfo = qx/sudo lxc-info -n $container -S -H/;

    for my $line (@lxcinfo) {
        if ($line =~ /^Memory use:\s+([0-9]+)$/) {
            $containermemusage = "$1";
        }
        if ($line =~ /^ TX bytes:\s+([0-9]+)$/) {
            $containertxbytes = "$1";
        }
        if ($line =~ /^ RX bytes:\s+([0-9]+)$/) {
            $containerrxbytes = "$1";
        }
        if ($line =~ /^BlkIO use:\s+([0-9]+)$/) {
            $containerio = "$1";
        }
    }

    if ($containermemusage >= $containermemlimit * 0.75) {
        push(@problems, $container . ' High memory, ');
    }

    $mp->add_perfdata(
        label => $container . " memory used",
        uom => "B",
        value => $containermemusage
    );
    $mp->add_perfdata(
        label => $container . " network TX",
        uom => "c",
        value => $containertxbytes
    );
    $mp->add_perfdata(
        label => $container . " network RX",
        uom => "c",
        value => $containerrxbytes
    );
    $mp->add_perfdata(
        label => $container . " disk IO",
        uom => "c",
        value => $containerio
    );
}

if (@problems) {
    $mp->nagios_exit('CRITICAL', print join(" ", @problems));
}

$mp->nagios_exit('OK', '');
