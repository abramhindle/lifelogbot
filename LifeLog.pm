package LifeLog;
use Modern::Perl;
use Moose;
use Fatal qw(open close);
use LifeLogEntry;

has 'current_log' => (is => 'rw');#, isa =>'LifeLogEntry');
has 'timeout'     => (is => 'rw', default => 600 );
has 'org_out_filename' => (is => 'rw', default => "logs/log.org");
has 'log_entries' => (is =>'rw', isa => 'ArrayRef', default => sub { [] });

sub add_line {
    my ($self, @lines) = @_;
    my $log = $self->_ensure_log();
    my $now = time();
    unless ($now - $log->time() < $self->timeout) {
        # save out
        $self->close_message();
    }
    $self->_add_line(@lines);
}

sub _add_line {
    my ($self, @lines) = @_;
    warn @lines;
    my $log = $self->_ensure_log();
    $log->append( @lines );
}

sub _new_log {
    my ($self) = @_;
    $self->current_log( LifeLogEntry->new( time => time() ) );
}

sub _ensure_log {
    my ($self) = @_;
    if (!$self->current_log()) {
        $self->_new_log();
    }
    return $self->current_log();
}


sub close_message {
    my ($self) = @_;
    unless ( $self->current_log() && $self->current_log->empty() ) {
        $self->write_message( $self->current_log() )
    }
    $self->current_log( undef );
}

sub write_message {
    my ($self) = @_;
    my $org = $self->current_log->org();
    $self->append_org( $org );
    $self->append_log( $self->current_log );
}
sub append_log {
    my ($self, $log) = @_;
    push @{$self->log_entries()}, $log;
}
sub append_org {
    my ($self, $org) = @_;
    $self->append_org_file($self->org_out_filename, $org );    
}
sub append_org_file {
    my ($self, $filename, $org) = @_;
    warn "Appending to file $filename";
    open(my $fd, ">>", $filename);
    print $fd $org;
    print $fd $/;
    close($fd);
}

sub get_recent_log_entries {
    my ($self,$seconds) = @_;
    my $time = time() - $seconds;
    my @entries = grep { $_->time() > $time  } @{$self->log_entries};
    return @entries;
}

1;
