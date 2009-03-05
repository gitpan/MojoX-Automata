package MyApp::Automata::CheckAccess;

use strict;
use warnings;

use base 'Mojo::Base';

sub run {
    my ($self, $c) = @_;

    my $endpoint = $c->match->endpoint;
    return 1 unless $endpoint;

    my $name = $endpoint->name;

    return 1 if $name eq 'root';

    return 0;
}

1;
