package StubAgent;
use Moose;

has 'cb' => (is =>'rw');

sub interpret_command {
    my ($self) = @_;
    warn "CALLBACK!";
    $self->cb->($self);
}

1;


