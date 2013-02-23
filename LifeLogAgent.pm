package LifeLogAgent;
use Modern::Perl;
use Moose;
use Fatal qw(open close);
use LifeLogEntry;
use LifeLog;
use AnyEvent;
use Time::Piece;
use Schedule;

sub dfl_commands {
    my %commands = (
                    save => sub {
                        my ($self,@other) = @_;
                        $self->lifelog->close_message();
                        return "Saved Message";
                    },
                    say => sub {
                        my ($self, $say, @other) = @_;
                        my $msg = join(" ", @other);
                        $self->broadcast($msg);
                    },
                    #.c schedule weekly 12345 10:00 
                    schedule => sub {
                        my ($self, $schedule, @other) = @_;
                        $self->add_schedule(@other);
                    }
                   );
    return \%commands;
}

has "logfile" => (is => 'rw', default => "logs/log.org");
has "allowed_nick" => (is => 'rw', default => 'avi!abez@maxchats-vnf.87d.172.66.IP');
has "my_nick" => (is => 'rw', default=>'avi');
has "lifelog" => (is => 'rw', default=>sub { LifeLog->new() });
has "commands" => (is => 'rw', default=>sub { dfl_commands() });
has "properties" => (is => 'rw', default=>sub { {} });
has "schedule" => (is => 'rw', default=>sub { [] });
has "c" => (is => 'rw', default => sub {  AnyEvent->condvar  } );
has "connections" => (is => 'rw', default => sub { [] });

sub log_msg {
    my ($self, $msg) = @_;
    if ($msg =~ /^\.c\s+(.*)$/) {
        my $command = $1;
        return $self->interpret_command( $command );
    } else {
        $self->lifelog->add_line( split($/,$msg) );
        return $msg;
    } 
}

sub interpret_command {
    my ($self, $commandline) = @_;
    my @commandline = split(/\s+/, $commandline);
    my $command = $commandline[0] || "";
    return $self->execute_command($command, @commandline);
}

# Mon = 1 Sun = 7
#.c schedule weekly 12345 10:00 
sub add_schedule {
    my ($self, @command) = @_;
    eval {
        my $schedule = Schedule::make(@command);
        $schedule->agent( $self ); # add callback
        push @{$self->schedule()}, $schedule;
        $schedule->schedule();
    };
    if ($@) {
        return "ERROR: $@";
    }
}


sub broadcast {
    my ($self, @messages) = @_;
    foreach my $conn (@{$self->connections()}) {
        $conn->message(join($/,@messages));
    }
}
sub BUILD {
    my ($self) = @_;

    # schedule the repeating events
    foreach my $str (@{$self->schedule()}) {
        warn $str;
        my $schedule = Schedule::make_from_string ($str);
        $schedule->agent( $self ); # add callback
        $schedule->schedule();
    }
}

sub add_connection {
    my ($self, $conn) = @_;
    push @{$self->connections}, $conn;
}

sub register_command {
    my ($self, $commandname, $command) = @_;
    if (@_ == 2) {
        $command = $commandname;
        $commandname = $command->command_name;
    }
    # register command
    $self->commands->{$commandname} = sub { 
        my ($agent,$commandname,@args) = @_;
        return $command->call_back( $self, @args );
    };
}

sub execute_command {
    my ($self, $command, @commandline) = @_;
    if (exists $self->commands()->{$command}) {
        return $self->commands()->{$command}->($self,$command,@commandline);
    }
    return "Error: Could not find command!";
}
1;
