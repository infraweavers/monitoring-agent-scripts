#!/usr/bin/perl
use strict;
use warnings;
use Monitoring::Plugin;
use File::Find;
use File::Basename;

my $mp = Monitoring::Plugin->new(
    usage => "Usage: just run it",
    plugin => $0,
    shortname => 'DNS queries processed by systemd-resolved',
    blurb => 'How many DNS queries systemd-resolved is handling',
    timeout => 10
);

my $queries = qx(resolvectl statistics | awk '/Total Transactions: / { print \$3 }');
chomp $queries;

$mp->add_perfdata(
    label => "DNS Queries",
    value => $queries,
    uom => "c",
);

$mp->nagios_exit('OK', '');
