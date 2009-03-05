package MyApp::Automata::Dispatch;

use strict;
use warnings;

use base 'Mojo::Base';

__PACKAGE__->attr('routes');

sub run {
    my ($self, $c) = @_;

    my $ok = $self->routes->dispatch($c, $c->stash->{match});

    return $ok ? $c->res->code || 200 : 500;
}

1;
