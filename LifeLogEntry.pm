package LifeLogEntry;
use Modern::Perl;
use Moose;
use Time::Piece;
use Data::Dumper;

has 'time' => ( is => 'rw', default => sub { time() } );
has 'message' => (is => 'rw', isa =>'ArrayRef', default => sub { [] });

sub empty {
    my ($self) = @_;
    return length( $self->message ) <= 0;
}

sub append {
    my ($self, @lines) = @_;
    unless ($self->message()) {
        $self->message([]);
    }
    push @{$self->message()}, @lines;
}
sub org {
    my ($self) = @_;
    my $t = localtime($self->time());
    my $ts = $t->strftime('%Y-%m-%d %a %H:%M');
    my $head = "$/* Note <${ts}>";
    my $message = join("$/\t",$head,@{$self->message()});
    return $message;
}

1;
