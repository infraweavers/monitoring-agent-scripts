#!/usr/bin/perl
use strict;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
use Monitoring::Plugin;
use MIME::Base64;

my $plugin = Monitoring::Plugin->new (
	usage => '',
	plugin => $0,
	shortname => 'Check monitoring-agent info',
	blurb => 'Checks monitoring-agent info',
	timeout => "10s"
);

my $units = {
	"Mallocs" => "c",
	"Frees" => "c",
	"TotalAlloc" => "c",
	"NumGC" => "c",
	"NumForcedGC" => "c",
	"PauseTotalNs" => "c",
	"PauseTotalNs" => "c",
};

my $user_agent = LWP::UserAgent->new();

$plugin->add_arg(spec => 'hostname|h=s', help => 'hostname or ip', required => 1);
$plugin->add_arg(spec => 'port|p=i', help => 'port number', required => 1);
$plugin->add_arg(spec => 'insecure|i!', help => 'ignore TLS Certificate checks', required=> 0);
$plugin->add_arg(spec => 'cacert|e=s', help => 'CA certificate', required => 0);
$plugin->add_arg(spec => 'certificate|c=s', help => 'certificate file', required => 0);
$plugin->add_arg(spec => 'key|k=s', help => 'key file', required => 0);
$plugin->add_arg(spec => 'username|u=s', help => 'username', required => 0);
$plugin->add_arg(spec => 'password|p=s', help => 'password', required => 0);

$plugin->getopts;

my $username = exists($ENV{'MONITORING_AGENT_USERNAME'}) ? $ENV{'MONITORING_AGENT_USERNAME'} : $plugin->opts->username;
my $password = exists($ENV{'MONITORING_AGENT_PASSWORD'}) ? $ENV{'MONITORING_AGENT_PASSWORD'} : $plugin->opts->password;

my $base64creds = encode_base64("$username" . ":" . "$password");
chomp($base64creds);

my $socket = $plugin->opts->hostname . ":" . $plugin->opts->port;

if($plugin->opts->insecure) {
	$user_agent->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0x00);	
}
if($plugin->opts->cacert){
	$user_agent->ssl_opts( "SSL_ca_file" => $plugin->opts->cacert );
}
if($plugin->opts->certificate) {
	if( ! -e $plugin->opts->key ) {
		print "invalid key file.\n";
		exit UNKNOWN;
	}

	$user_agent->ssl_opts(
		SSL_cert_file => $plugin->opts->certificate, 
		SSL_key_file => $plugin->opts->key
	);
}

alarm $plugin->opts->timeout;

my $response = $user_agent->get("https://$socket/v1/info",
	'Content-Type'=> 'application/json',
	'Authorization' => "Basic $base64creds",
);

if ($response->code ne 200) {
	print $response->message."\n".$response->content."\n";
	exit UNKNOWN
}

my $response_object = decode_json $response->content;

while (my ($name, $value) = each %{$response_object->{'Memory'}}) {
	if (ref $value eq '') {

		my $unit = "";
		$unit = $units->{$name} if exists($units->{$name} );
		next if $name eq "GCCPUFraction";

		$plugin->add_perfdata(
			label => $name,
			value => $value,
			uom => $unit
		);
	}
}

$plugin->nagios_exit(OK, "OK");
