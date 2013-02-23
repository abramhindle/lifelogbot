package EmailCommand;
use MIME::Lite;
use Data::Dumper;
use Moose;

has 'from' => (is => 'rw', default => 'avibot@softwareprocess.es');
has 'server' => (is => 'rw', default => 'fragile');
has 'to' => (is => 'rw');
has 'subject' => (is => 'rw', default => 'LifeLogBot');

sub call_back {
    my ($self, $agent, @commands) = @_;
    $self->send_email( @commands  );
}

sub send_email {
    my ($self,@data) = @_;
    MIME::Lite->send('smtp', "fragile");
    my $t = time();
    my %email = (
                 From     => $self->from,
                 To       => $self->to,
                 Subject  => $self->subject,
                 Data     => join($/,@data).$/
                );
    if ($email{Data} =~ /^Subject:\s([^\r\n]+)[\r\n]/m) {
        $email{Subject} = $1;
        my @lines = split($/,$email{Data});
        shift @lines;
        $email{Data} = join($/, @lines).$/;
    }
    warn Dumper(\%email,\@data);
    my $msg = MIME::Lite->new( %email );

    $msg->send() || die "Failed at sending";
}

sub command_name {
    return "email";
}

1;
