package MyApp::Automata::RenderView;

use strict;
use warnings;

use base 'Mojo::Base';

sub run {
    my ($self, $c) = @_;

    my $template = $c->stash->{template};

    unless ($template) {
        if (my $endpoint = $c->match->endpoint) {
            my @parts = split(/_/, $endpoint->name);

            $template = join('/', @parts);

            $c->stash(template => $template,);
        }
    }

    $c->app->log->debug("Rendering $template template");

    return $c->render ? 1 : 0;
}

1;
