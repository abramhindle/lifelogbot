package Jabber;
# Model an IRC connection
use AnyEvent;
use AnyEvent::XMPP::Client;
use Moose;

has "jabber_password" => (is =>'rw');
has "jabber_user" => (is =>'rw');
has "jabber_port" => (is =>'rw');
has "jabber_server" => (is =>'rw');
has "jabber_domain" => (is =>'rw');
has "agent"=> (is =>'rw');
has "cl"=> (is =>'rw');
has "jabber_jid" => (is => 'rw');

sub make_from_config {
    my ($agent, $config) = @_;
    my %jabber = ();
    my $prop = $config->{properties} || {};
    foreach my $key (keys %{$prop}) {
        if ($key =~ /^jabber.*/) {
            $jabber{$key} = $prop->{$key};
        }
    }
    return Jabber->new( agent=>$agent, %jabber );
}

sub BUILD {
    my ($self) = @_;
    my $cl = AnyEvent::XMPP::Client->new();
    $self->cl($cl);

    warn $self->jabber_user;

    $cl->add_account(
                     $self->jabber_user,
                     $self->jabber_password,
                     $self->jabber_server,         # server
                     $self->jabber_port,                      # port
                     # other weird args
                     { domain => $self->jabber_domain, old_style_ssl => 1 } 
                    );
    
    my $reconnect = sub {
	my ($client) = @_;
	$client->disconnect;		
	warn "reconnecting XMPP (wait 30)";
	AnyEvent->timer (after => 30, cb => sub {
                             my ($client) = @_;
                             warn "reconnecting XMPP!";
                             $client->connect;
                         });
    };
    
    $cl->reg_cb(
                message => sub {
                    my ($client, $account, $message) = @_;
                    my $msg = "$message";
                    my $response = $self->agent->log_msg($msg);
                    my $r = $message->make_reply();
                    $self->jabber_jid($r->to);
                    $r->add_body("ECHO: $response");
                    $client->send_message($r);
                },
                contact_request_subscribe => sub {
                    my ($client, $account, $roster, $contact, $message) = @_;
                    $contact->send_subscribed;
                },
                session_error => $reconnect,
                disconnect => $reconnect,
               );
    
    
    $cl->start;
    return $self;
}

sub message {
    my ($self, $message) = @_;
    if ($self->jabber_jid()) {
        warn "JID:".$self->jabber_jid();
        my $msg = AnyEvent::XMPP::IM::Message->new(
                                                   body=>$message, 
                                                   to => $self->jabber_jid()
                                                  );
        $self->cl->send_message( $msg );
    }
}
1;
