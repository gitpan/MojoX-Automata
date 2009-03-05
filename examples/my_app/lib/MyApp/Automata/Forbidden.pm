package MyApp::Automata::Forbidden;

use strict;
use warnings;

use base 'Mojo::Base';

sub run {
    my ($self, $c) = @_;

    $c->res->code(403);

    $c->stash(template => '403.phtml');

    return 1;
}

1;
