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
	shortname => 'Check via monitoring-agent',
	blurb => 'Checks via monitoring-agent',
	timeout => 10
);

my $user_agent = LWP::UserAgent->new();

$plugin->add_arg(spec => 'insecure|i!', help => 'ignore TLS Certificate checks', required=> 0);
$plugin->add_arg(spec => 'template|t=s', help => 'pnp4nagios template', required => 0);
$plugin->add_arg(spec => 'hostname|h=s', help => 'hostname or ip', required => 1);
$plugin->add_arg(spec => 'port|p=i', help => 'port number', required => 1);
$plugin->add_arg(spec => 'username|u=s', help => 'username', required => 1);
$plugin->add_arg(spec => 'password|p=s', help => 'password', required => 1);
$plugin->add_arg(spec => 'executable|e=s', help => 'executable path', required => 1);
$plugin->add_arg(spec => 'cacert|e=s', help => 'CA certificate', required => 0);
$plugin->add_arg(spec => 'certificate|e=s', help => 'client certificate', required => 0);
$plugin->add_arg(spec => 'key|e=s', help => 'client key', required => 0);

$plugin->getopts;

my $username = exists($ENV{'MONITORING_AGENT_USERNAME'}) ? $ENV{'MONITORING_AGENT_USERNAME'} : $plugin->opts->username;
my $password = exists($ENV{'MONITORING_AGENT_PASSWORD'}) ? $ENV{'MONITORING_AGENT_PASSWORD'} : $plugin->opts->password;

my $base64creds = encode_base64("$username" . ":" . "$password");
chomp($base64creds);

my $socket = $plugin->opts->hostname . ":" . $plugin->opts->port;

$user_agent->credentials($socket, "Access restricted", $username, $password);

if($plugin->opts->insecure) {
	$user_agent->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0x00);	
}

my $input = {
	"path" => $plugin->opts->executable,
	"args" => \@ARGV,
};

alarm $plugin->opts->timeout;

if($plugin->opts->cacert){
	$user_agent->ssl_opts( "SSL_ca_file" => $plugin->opts->cacert );
	if($plugin->opts->certificate && $plugin->opts->key){
		$user_agent->ssl_opts( "SSL_cert_file" => $plugin->opts->certificate );
		$user_agent->ssl_opts( "SSL_key_file" => $plugin->opts->key );	
	}
}

my $response = $user_agent->post("https://$socket/v1/runexecutable",
	'Content-Type'=> 'application/json',
	'Authorization' => "Basic $base64creds",
	Content => encode_json $input
);

if ($response->code ne 200) {
	print $response->message."\n".$response->content."\n";
	exit UNKNOWN
}

my $response_object = decode_json $response->content;

print $response_object->{'output'};

my $exitcode = $response_object->{'exitcode'};
$exitcode = UNKNOWN if $exitcode > UNKNOWN;

exit $exitcode;
