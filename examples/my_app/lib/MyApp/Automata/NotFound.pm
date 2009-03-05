package MyApp::Automata::NotFound;

use strict;
use warnings;

use base 'Mojo::Base';

sub run {
    my ($self, $c) = @_;

    $c->res->code(404);

    # with no match set it to default, so all url_for calls will work
    $c->tx->req->url->parse('/');

    $c->match($c->app->routes->match($c->tx));

    $c->stash(template => '404.phtml');

    return 1;
}

1;
