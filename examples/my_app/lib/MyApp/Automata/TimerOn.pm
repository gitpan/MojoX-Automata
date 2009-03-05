package MyApp::Automata::TimerOn;

use strict;
use warnings;

use base 'Mojo::Base';

use Time::HiRes 'gettimeofday';

sub run {
    my $self = shift;
    my ($c) = @_;

    $c->stash->{ start_time } = [ gettimeofday ];

    return 1;
}

1;
