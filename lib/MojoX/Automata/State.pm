package MojoX::Automata::State;

use warnings;
use strict;

use base 'Mojo::Base';

require Carp;
use Mojo::Loader;

__PACKAGE__->attr([qw/ name namespace /] => (chained => 1));
__PACKAGE__->attr([qw/_handler _to/]);
__PACKAGE__->attr(
    loader => (chained => 1, default => sub { Mojo::Loader->new }));

sub handler {
    my $self = shift;

    # Shortcut
    return $self->_handler unless @_;

    # Either coderef or object
    if (ref $_[0]) {
        $self->_handler($_[0]);
    }

    # Class name with optional arguments
    else {
        my ($class, @args) = @_;

        $class = $self->namespace . '::' . $class if $self->namespace;

        $self->loader->load($class);
        $self->_handler($class->new(@args));
    }

    return $self;
}

sub to {
    my $self = shift;

    # Switch to another state without any transition
    if (@_ == 1) {
        $self->_to($_[0]);
    }

    # Swith to another state on behalf of transitions
    else {
        my %transitions = @_;
        $self->_to({%transitions});
    }

    return $self;
}

sub next {
    my $self = shift;

    my $handler = $self->_handler;
    Carp::croak($self->name . ': No handler defined') unless $handler;

    my $rv = ref $handler eq 'CODE' ? $handler->(@_) : $handler->run(@_);

    my $to = $self->_to;
    return ref $to eq 'HASH' ? $to->{$rv} : $to;
}

1;
__END__

=head1 NAME

MojoX::Automata::State - State class for MojoX::Automata

=head1 DESCRIPTION

This is used internally, but a new instance is returned every time a new state
is created.

=head1 METHODS

=head2 C<handler>

Defines a new handler.

=head2 C<to>

Defines a new transition.

=head2 C<next>

Switches to the next state.

=head1 SEE ALSO

    MojoX::Automata

=cut
