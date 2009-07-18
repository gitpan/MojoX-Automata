package
MyApp;

use strict;
use warnings;

use base 'MojoliciousX::Automata';

use MojoX::Automata;

__PACKAGE__->attr(
    config => (default => sub { {languages => [qw/ de en /]}; }));

# This method will run for each request
sub dispatch {
    my ($self, $c) = @_;

    # Run automata
    $self->automata->run($c);
}

# This method will run once at server start
sub startup {
    my $self = shift;

    # Use our own context class
    $self->ctx_class('MyApp::Context');

    # Routes
    my $r = $self->routes;

    # Default route
    $r->route('/')->to(controller => 'root', action => 'default', id => 1)
      ->name('root');

    my $automata = $self->automata;

    $automata->namespace('MyApp::Automata');

    # Registering states

    # Detect if static file was requested
    $automata->state('S')->handler('Static', static => $self->static)
      ->to(0 => 'l', 1 => 'E');

    # Detect language from the url (http://example.com/en/stuff) etc.
    $automata->state('l')
      ->handler('DetectLang', languages => $self->config->{languages})
      ->to('t_on');

    # Get page rendering time
    $automata->state('t_on')->handler('TimerOn')->to('m');

    # Mojo Routes (just the part that matches the route without calling
    # appropriate controller)
    $automata->state('m')->handler('Match', routes => $self->routes)
      ->to(0 => 'n', 1 => 'u');

    # Serving 404 error
    $automata->state('n')->handler('NotFound')->to('v');

    # Mojo Routes controller call part
    $automata->state('d')->handler('Dispatch', routes => $self->routes)
      ->to(302 => 'E', 500 => 'e', 200 => 't_off', 404 => 'n', 403 => 'f');

    # Checking access
    $automata->state('a')->handler('CheckAccess')->to(0 => 'f', 1 => 'd');

    # Rendering view (no need to call $self->render in every controller)
    $automata->state('v')->handler('RenderView')->to(0 => 'e', 1 => 'E');

    # Serving 403 error
    $automata->state('f')->handler('Forbidden')->to('v');

    # Serving 500 error
    $automata->state('e')->handler('InternalError')->to('E');

    # Get user from cookie etc
    $automata->state('u')->handler('User')->to('a');

    $automata->state('t_off')->handler('TimerOff')->to('v');
}

1;
