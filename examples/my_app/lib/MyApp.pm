package MyApp;

use strict;
use warnings;

use base 'Mojolicious';

use MojoX::Automata;

__PACKAGE__->attr(automata => (default => sub { MojoX::Automata->new }));

__PACKAGE__->attr(
    config => (
        default => sub {
            {   languages      => [qw/ de en /],
                language_names => {
                    de => 'Deutsch',
                    en => 'English',
                },
            };
        }
    )
);

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
    $automata->register('S' => 'Static', static => $self->static);

    # Get page rendering time
    $automata->register('t_on'  => 'TimerOn');
    $automata->register('t_off' => 'TimerOff');

    # Detect language from the url (http://example.com/en/stuff) etc.
    $automata->register(
        'l'       => 'DetectLang',
        languages => $self->config->{languages}
    );

    # Mojo Routes (just the part that matches the route without calling
    # appropriate controller
    $automata->register('m' => 'Match', routes => $self->routes);

    # Mojo Routes controller call part
    $automata->register('d' => 'Dispatch', routes => $self->routes);

    # Checking access
    $automata->register('a' => 'CheckAccess');

    # Rendering view (no need to call $self->render in every controller)
    $automata->register('v' => 'RenderView');

    # Serving 404 error
    $automata->register('n' => 'NotFound');

    # Serving 403 error
    $automata->register('f' => 'Forbidden');

    # Serving 500 error
    $automata->register('e' => 'InternalError');

    # Get user from cookie etc
    $automata->register('u' => 'User');

    # End state
    $automata->register('E' => 'End');

    # Setting Start and End states
    $automata->start('S')->end('E');


    # Setting transitions between states

    # If it was a static file request end the automata, otherwise go to the
    # state of language detection
    $automata->add_path('S', 0 => 'l', 1 => 'E');

    # After language detection without any transitions switch to timer
    $automata->add_path('l' => 't_on');

    # After time got the routes matching state
    $automata->add_path('t_on' => 'm');

    # If route is find get user, otherwise switch to 404 state
    $automata->add_path('m', 0 => 'n', 1 => 'u');

    # After getting the user check his/her access to specific route (that is why
    # we didn't call controller just after the match
    $automata->add_path('u' => 'a');

    # If user has access call dispatcher, otherwise serve 403
    $automata->add_path('a', 0 => 'f', 1 => 'd');

    # Dispatcher (calling controller) can return different answers, go to
    # the right state after that
    $automata->add_path(
        'd',
        302 => 'E',
        500 => 'e',
        200 => 't_off',
        404 => 'n',
        403 => 'f'
    );

    # Turn off the timer
    $automata->add_path('t_off' => 'v');

    # Switch from 404 and 500 to the view
    $automata->add_path('n' => 'v');
    $automata->add_path('f' => 'v');

    # Render the view, if there were any rendering errors, switch to 500
    $automata->add_path('v', 0 => 'e', 1 => 'E');

    # End automata
    $automata->add_path('e' => 'E');
}

1;
