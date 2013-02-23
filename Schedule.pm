package Schedule;
use Moose;
use AnyEvent;
use Time::Seconds;
use Time::Piece;

has days => (is=>'rw', default => sub { [] });
has timers => (is=>'rw', default => sub { [] });
has time => (is=>'rw');
has command => (is=>'rw');
has agent => (is=>'rw');


# schedule for a while
sub schedule {
    my ($self) = @_;
    my $base_seconds = $self->time_in_seconds();
    my $today = start_of_today();
    my $todaytime = $today + $base_seconds;
    my %days = map { $_ => 1 } @{$self->days};
    my $now = time();
    for my $n (0..364) {
        my $dayoffset = ONE_DAY * $n;
        my $time = $todaytime + $dayoffset;
        my $tp = Time::Piece->new($time);
        # get the weekday
        my $wday = $tp->wday;
        # if it matches the weekday and the time is in the future
        if ($days{$wday} && $time >= $now) {
            my $diff = $time - $now;
            print STDERR $diff . "\t";
            $self->add_timer(AnyEvent->timer(
                            after=> $diff,
                            cb =>
                            sub {
                                warn "Callback!";
                                $self->call_back();
                            }
                           ));
        }
    }
    print STDERR $/;
}

sub add_timer {
    my ($self, $timer) = @_;
    push @{$self->timers}, $timer;
}

sub call_back {
    my ($self,@o) = @_;
    warn "Callback fired! ".@{$self->command()};
    if ($self->agent) {
        $self->agent->interpret_command(join(" ", @{$self->command}));
    }
}

sub start_of_today {
    my $tnow = time();#Time::Piece->new(time());
    my $now = Time::Piece->new($tnow);
    return ($now->epoch - ($now->hour * 3600 + $now->minute * 60 + $now->sec));
    #my $ymd = join("-", $now->year, $now->mon, $now->mday);
    #my $start = Time::Piece->strptime("$ymd 00:00", '%Y-%m-%d %H:%M')->epoch;
    #return $start;
}
# since start of day
sub time_in_seconds {
    my ($self) = @_;
    my $time = $self->time();
    my ($hours, $mins) = split(/\:/, $time);
    $hours =~ s/^0//;
    $mins =~ s/^0//;
    # now they are numbers (ha)
    return 3600*$hours + 60*$mins;
}

sub make_from_string {
    my ($str) = @_;
    my @line = split(/\s+/, $str);
    return make(@line);
}

sub make {
    my ($first,@commands) = @_;
    if ($first eq "weekly") {
        return make_weekly( @commands  );
    } elsif ($first eq "daily") {
        return make_daily( @commands );
    } else {
        die "Unknown Schedule [$first] [@commands]";
    }
}

sub make_weekly {
    my ($days, $time, @commands) = @_;
    my @days = split(//, $days);    
    return Schedule->new(days=>[@days], time=>$time, command => [@commands]);
}

sub make_daily {
    my ($time, @commands) = @_;
    return make_weekly( "1234567", $time, @commands );
}

sub make_example {
    return make_from_string("weekly 5 10:00 say hi");
}

1;
