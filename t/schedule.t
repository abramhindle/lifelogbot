#!/usr/bin/perl -w
BEGIN {
      push @INC,qw(..);
}
use Test::Simple tests => 3;
use Schedule;
use Modern::Perl;
use AnyEvent;
use StubAgent;

my $c = AnyEvent->condvar;


{
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        my $diff = $sec + 60*$min + 3600*$hour;
        my $t =  time();
        my $t2 = Schedule::start_of_today();        
        ok( $t - $t2 == $diff );
}


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $s = "$hour:".($min+1);
my $sched = Schedule::make_daily($s, "do something");       
my $v = 0;
my $agent = StubAgent->new(cb => sub { 
                              ok(1);
                              exit(0);
                              });                                         
                                     
$sched->agent( $agent );
$sched->schedule();

ok(1);

my $timer = AnyEvent->timer( after=> 61, cb => sub { ok(0); die "Didn't already exit!" } );

$c->wait();

