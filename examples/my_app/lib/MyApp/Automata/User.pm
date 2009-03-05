package MyApp::Automata::User;

use strict;
use warnings;

use base 'Mojo::Base';

sub run {
    my ($self, $c) = @_;

    # check cookie, load session, etc...
    # $c->user('admin');
}

1;
