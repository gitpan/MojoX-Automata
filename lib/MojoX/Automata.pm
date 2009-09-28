package MojoX::Automata;

use strict;
use warnings;

use base 'Mojo::Base';

our $VERSION = '0.501';

use constant DEBUG => $ENV{MOJOX_AUTOMATA_DEBUG} || 0;

require Carp;

use MojoX::Automata::State;

__PACKAGE__->attr('namespace');
__PACKAGE__->attr('_start');
__PACKAGE__->attr('_states' => sub { {} });
__PACKAGE__->attr('limit' => (10000));

sub state {
    my $self = shift;
    my $name = shift;

    return $self->_states->{$name} if $self->_states->{$name};

    $self->_start($name) unless $self->_start;

    my $state = MojoX::Automata::State->new(
        name      => $name,
        namespace => $self->namespace
    );

    $self->_states->{$name} = $state;

    return $state;
}

sub run {
    my $self = shift;

    my $name = $self->_start;

    my $count = 0;

    my $state = $self->_states->{$name};
    while ($state) {

        warn $name if DEBUG;
        # Get the next state
        $name = $state->next(@_);

        last unless $name;

        warn ' -> ' . $name if DEBUG;

        # Switch to the next state
        $state = $self->_states->{$name};

        if (++$count >= $self->limit) {
            die 'Looks like an infinite loop'
        }
    }

    return $self;
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
    # You can find all these states in the examples/ dir of the distribution

=head1 DESCRIPTION

L<MojoX::Automata> is a Mojo finite automata dispatching mechanizm.

=head1 ATTRIBUTES

=head2 C<namespace>

    # Set namespace for the state classes
    $self->namespace(__PACKAGE__);

=head2 C<limit>

Holds state change limit number. Dies with an error 'Look like an infinite loop'
after limit is reached  It is 10000 by default.

=head1 METHODS

L<MojoX::Automata> inherits all methods from
L<Mojo::Base> and implements the following the ones.

=head2 C<state>

    Register a new state(s).

    $automata->state('routes');

=head2 C<handler>

    Add a new handler to the state.

    # Object
    $state->handler(Handler->new);

    # Will load Handler class, and will create instance with arguments provided
    $state->handler('Handler' => (arg => 'foo'));

    # Pass anonymous subroutine
    $state->handler(sub { return 1 });

=head2 C<to>

    Add path between states.

    # Swith from state B<a> to B<a> without any return value checks.
    $state->to('r' => 'a');

    # Swith from state B<s> to B<e> if state returns B<1>.
    $state->to('s', 1 => 'e');

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
