package DailyReport;
# Needs EmailCommand in agent
use MIME::Lite;
use Moose;

sub call_back {
    my ($self, $agent, @commands) = @_;
    $self->send_email( $agent, @commands  );
}
sub send_email {
    my ($self, $agent) = @_;
    my $report_txt = $self->get_report($agent);
    $agent->execute_command("email", $report_txt);
}

sub get_report {
    my ($self, $agent) = @_;
    my $lifelog = $agent->lifelog;    
    my @entries = ($lifelog->get_recent_log_entries( 60 * 60 * 24 ));
    if ($lifelog->current_log && ! $lifelog->current_log->empty ) {
        unshift @entries, $lifelog->current_log;
    }
    warn scalar(@entries);
    my $report = join("$/$/", (map { $_->org } @entries) );
    return "Subject: LifeLogBot Daily Report\n$report";
}

sub command_name {
    return "dailyreport";
}

1;
