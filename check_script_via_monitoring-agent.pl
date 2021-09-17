#!/usr/bin/perl
use strict;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
use Monitoring::Plugin;
use File::Slurp;
use MIME::Base64;

my $plugin = Monitoring::Plugin->new (
	usage => '',
	plugin => $0,
	shortname => 'Check via monitoring-agent',
	blurb => 'Checks via monitoring-agent',
	timeout => "10s"
);

my $user_agent = LWP::UserAgent->new();

$plugin->add_arg(spec => 'insecure|i!', help => 'ignore TLS Certificate checks', required=> 0);
$plugin->add_arg(spec => 'template|t=s', help => 'pnp4nagios template', required => 0);
$plugin->add_arg(spec => 'hostname|h=s', help => 'hostname or ip', required => 1);
$plugin->add_arg(spec => 'port|p=i', help => 'port number', required => 1);
$plugin->add_arg(spec => 'cacert|e=s', help => 'CA certificate', required => 0);
$plugin->add_arg(spec => 'certificate|c=s', help => 'certificate file', required => 0);
$plugin->add_arg(spec => 'key|k=s', help => 'key file', required => 0);
$plugin->add_arg(spec => 'username|u=s', help => 'username', required => 0);
$plugin->add_arg(spec => 'password|p=s', help => 'password', required => 0);
$plugin->add_arg(spec => 'executable|e=s', help => 'executable path', required => 1);
$plugin->add_arg(spec => 'script|s=s', help => 'script location', required => 1);
$plugin->add_arg(spec => 'timeout|t=s', help => 'timeout (e.g. 10s)', required => 0);

$plugin->getopts;

my $username = exists($ENV{'MONITORING_AGENT_USERNAME'}) ? $ENV{'MONITORING_AGENT_USERNAME'} : $plugin->opts->username;
my $password = exists($ENV{'MONITORING_AGENT_PASSWORD'}) ? $ENV{'MONITORING_AGENT_PASSWORD'} : $plugin->opts->password;

my $socket = $plugin->opts->hostname . ":" . $plugin->opts->port;

if($plugin->opts->insecure) {
	$user_agent->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0x00);	
}

if($plugin->opts->cacert){
	$user_agent->ssl_opts( "SSL_ca_file" => $plugin->opts->cacert );
}

my $scriptContent = read_file($plugin->opts->script, { binmode => ':bytes' });

if($plugin->opts->script =~ /.ps1$/) {
	if((substr($scriptContent, -4) ne "\r\n\r\n") and (substr($scriptContent, -2) ne "\n\n")) {
		print "Invalid powershell script, the script must end with two blank lines\n";
		exit UNKNOWN;	
	}
}

my $input = {
	"path" => $plugin->opts->executable,
	"args" => \@ARGV,
	"stdin" => $scriptContent,
	"timeout" => $plugin->opts->timeout
};

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

if( -e $plugin->opts->script.".minisig") {
	my $signatureContent = read_file($plugin->opts->script.".minisig");
	$input->{"stdinsignature"} = $signatureContent;
}

my $base64creds = encode_base64("$username" . ":" . "$password");
chomp($base64creds);

alarm $plugin->opts->timeout;

my $response = $user_agent->post("https://$socket/v1/runscriptstdin",
	'Content-Type'=> 'application/json',
	'Authorization' => "Basic $base64creds",
	Content => to_json $input
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
