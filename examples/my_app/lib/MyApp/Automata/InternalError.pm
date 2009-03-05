package MyApp::Automata::InternalError;

use strict;
use warnings;

use base 'Mojo::Base';

sub run {
    my ($self, $c) = @_;

    $c->app->static->serve_500($c);
}

1;
