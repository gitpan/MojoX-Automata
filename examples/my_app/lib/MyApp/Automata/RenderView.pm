package MyApp::Automata::RenderView;

use strict;
use warnings;

use base 'Mojo::Base';

sub run {
    my ($self, $c) = @_;

    return $c->render ? 1 : 0;
}

1;
