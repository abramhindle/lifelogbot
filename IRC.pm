package IRC;
# Model an IRC connection
use AnyEvent;
use AnyEvent::IRC::Client;
use Moose;
use Data::Dumper;

has "server" => (is =>'rw');
has "port"=> (is =>'rw');
has "nick"=> (is =>'rw');
has "ssl"=> (is =>'rw');
has "agent"=> (is =>'rw');
has "con"=> (is =>'rw');
has "my_nick" => (is => 'rw');
has "allow_nick" => (is => 'rw');

sub make_from_config {
    my ($agent,$config) = @_;
    return IRC->new(
             agent => $agent,
             my_nick => $config->{my_nick},
             allow_nick => $config->{allow_nick},
             %{$config->{properties}->{irc}}
            );
}

sub BUILD {
    my ($self) = @_;
    $self->irc();
    return $self;
}
sub irc {
    my ($self) = @_;
    my $con = new AnyEvent::IRC::Client;
    my $mynick = $self->my_nick;
    my $allowednick = $self->allow_nick;
    warn $self->server;
    $self->con($con);
    $con->reg_cb (connect => sub {
                      my ($con, $err) = @_;
                      if (defined $err) {
                          warn "connect error: $err\n";
                          return;
                      }
                  });
    $con->reg_cb (registered => sub { print "I'm in!\n"; });
    $con->reg_cb (disconnect => sub { print "I'm out!\n"; $self->agent->c->broadcast });
    $con->reg_cb (
                  sent => sub {
                      my ($con) = @_;
                      if ($_[2] eq 'PRIVMSG') {
                          print "Sent message!\n";
                          print join("\t",@_).$/;
                      }
                  }
                 );

    $con->send_srv(
                    PRIVMSG => $mynick,
                    "Hello $mynick ! I am Avi Botter!"
                   );

    $con->reg_cb (
                  privatemsg => sub {
                      my ($con, $nick, $ircmsg) = @_;
                      my $prefix = $ircmsg->{prefix};
                      my ($_, $msg)  = @{$ircmsg->{params}};
                      unless (exists $allowednick->{$prefix} && $allowednick->{$prefix}) {
                          warn "Not allowed! [$prefix] [$msg]";
                          return;
                      }
                      warn $msg;
                      my $response = $self->agent->log_msg($msg);
                      $con->send_srv (
                                      PRIVMSG => $prefix,
                                      $response
                                     );
                  }
                 );

    
    $con->enable_ssl($self->ssl);
    $con->connect ($self->server(), $self->port(), { ssl => $self->ssl(), nick => $self->nick() });
    warn "IRC Going!";
}

sub message {
    my ($self, $message) = @_;
    foreach my $msg (split($/, $message)) {
        $self->con->send_srv(
                             PRIVMSG => $self->my_nick,
                             $msg
                            );
    }
}

sub DEMOLISH {
    my ($self) = @_;
    $self->con->disconnect if ($self->con);
}

1;
