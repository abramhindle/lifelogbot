package CloseReport;
use Moose;

sub call_back {
    my ($self, $agent, @commands) = @_;
    $agent->lifelog->close_message();
}

sub command_name {
    return "close";
}

1;
