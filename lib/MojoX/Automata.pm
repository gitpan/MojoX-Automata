package MojoX::Automata;

use strict;
use warnings;

use base 'Mojo::Base';

our $VERSION = '0.01';

use constant DEBUG => $ENV{MOJOX_AUTOMATA_DEBUG} || 0;

require Carp;
use Mojo::Loader;

__PACKAGE__->attr(
    loader => (chained => 1, default => sub { Mojo::Loader->new }));
__PACKAGE__->attr(namespace         => (chained => 1));
__PACKAGE__->attr([qw/ start end /] => (chained => 1));
__PACKAGE__->attr([qw/ _states _paths /] => (default => sub { {} }));

sub register {
    my ($self)  = shift;
    my ($state) = shift;
    my ($class) = shift;

    if (ref $class) {
        $self->_states->{$state} = $class;
    }
    else {
        $class = $self->namespace . '::' . $class if $self->namespace;

        $self->_states->{$state} = $self->loader->load_build($class, @_);
    }
}

sub add_path {
    my ($self)  = shift;
    my ($state) = shift;

    if (@_ == 1) {
        $self->_paths->{$state} = $_[0];
    }
    else {
        my %paths = @_;
        $self->_paths->{$state} = \%paths;
    }
}

sub run {
    my ($self) = shift;

    Carp::croak('Wrong start state')
      unless exists $self->_states->{$self->start};

    Carp::croak('Wrong end state') unless exists $self->_states->{$self->end};

    my $state = $self->start;
    warn "START" if DEBUG;
    do {
        my $dispatcher = $self->_states->{$state};

        my $object =
          ref $dispatcher eq 'HASH'
          ? $dispatcher->{object}
          : $dispatcher;

        my $rv = $object->run(@_);

        my $path = $self->_paths->{$state};

        if (ref $path eq 'HASH') {
            $state = $path->{$rv};

            warn "$rv -> $state" if DEBUG;
        }
        else {
            $state = $path;

            warn "* -> $state" if DEBUG;
        }
    } while ($state ne $self->end);

    $self->_states->{$self->end}->run(@_);

    warn "END" if DEBUG;
}

1;
__END__

=head1 NAME

MojoX::Automata - Call Mojo dispatchers in a finite automata manner

=head1 SYNOPSIS

    # Real app flow

                  no                                             yes
    static file -------> detect user language ---> routes match ---+
         |                                              |          |
         |                                           no |          v
     yes |                   404 ---<-------------------+       get user
         |                    |        403 <------+                |
         |                    +---->----+         |   not ok       v
         |                              |         +-----<----- check access
         |                 not ok       v                          | ok
         +-----<---- 500 <---------- render view <+   ok           v
         |            ^        ok       |         +---------- routes dispatch
         +-----<------^------<----------+                          |
         v            |                                not ok      |
        end           +---------------<---------------<------------+


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

    # You can find all these states in the examples/ dir of the distribution

=head1 DESCRIPTION

L<MojoX::Automata> is a Mojo finite automata dispatching mechanizm.

=head1 ATTRIBUTES

=head2 C<namespace>

    # Set namespace for the state classes
    $self->namespace(__PACKAGE__);

=head2 C<start>

    Set Start state.

=head2 C<end>

    Set End state.

=head1 METHODS

L<MojoX::Automata> inherits all methods from
L<Mojo::Base> and implements the following the ones.

=head2 C<register>

    Register a new state(s).

    $automata->register('routes' => 'Routes');

=head2 C<add_path>

    Add path between states.

    # Swith from state B<a> to B<a> without any return value checks.
    $automata->add_path('r' => 'a');

    # Swith from state B<s> to B<e> if state returns B<1>.
    $automata->add_path('s', 1 => 'e');

=head2 C<run>

    # Run automata. Parameters provided will be passed on to every state.
    $automata->run($c);

=head1 EXAMPLE
    
    You can find example app ready to go in examples/ directory.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Viacheslav Tikhanovskii, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
