package MyApp::Automata::Match;

use strict;
use warnings;

use base 'Mojo::Base';

__PACKAGE__->attr('routes');

sub run {
    my ($self, $c) = @_;

    my $match = $self->routes->match($c->tx);
    return 0 unless $match->endpoint;

    $c->match($match);

    $c->stash(
        match      => $match,
        controller => $match->captures->{controller},
        action     => $match->captures->{action}
    );

    return 1;
}

1;
