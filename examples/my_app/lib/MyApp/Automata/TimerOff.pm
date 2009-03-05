package MyApp::Automata::TimerOff;

use strict;
use warnings;

use base 'Mojo::Base';

use Time::HiRes qw/ gettimeofday tv_interval /;

sub run {
    my $self = shift;
    my ($c) = @_;

    $c->stash->{ elapsed_time } =
      tv_interval( $c->stash->{ start_time }, [ gettimeofday ] );

    return 1;
}

1;
