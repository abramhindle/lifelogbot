use AnyEvent;
use AnyEvent::IRC::Client;
use AnyEvent::XMPP::Client;
use strict;
use Time::Piece;
use Data::Dumper;
use LifeLogAgent;
use Modern::Perl;
use File::Slurp;
use JSON;
use IRC;
use Jabber;
use EmailCommand;
use DailyReport;

my $config = decode_json ( read_file ( 'config/config.json' ) ) || {};

my $c = AnyEvent->condvar;

my $lifelog = LifeLogAgent->new( c=> $c, %{$config});
my $agent = $lifelog;

$lifelog->add_connection( Jabber::make_from_config( $agent, $config ) );
$lifelog->add_connection( IRC::make_from_config( $agent, $config ) );

$lifelog->register_command( EmailCommand->new( %{$config->{properties}->{email}} ) );
$lifelog->register_command( DailyReport->new() );

#$cl->start;
$c->wait;
#$con->disconnect;

