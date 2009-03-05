package MyApp::Automata::Static;

use strict;
use warnings;

use base 'Mojo::Base';

__PACKAGE__->attr('static');

sub run {
    my $self = shift;
    my ($c) = @_;

    $c->res->headers->content_type(undef);

    return $self->static->dispatch($c);
}

1;
