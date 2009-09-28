package MojoliciousX::Automata;

use warnings;
use strict;

use base 'Mojolicious';

use MojoX::Automata;

__PACKAGE__->attr(automata => sub { MojoX::Automata->new });

sub dispatch {
    my ($self, $c) = @_;

    # Run automata
    $self->automata->run($c);
}

1;
__END__

=head1 NAME

MojoliciousX::Automata - MojoX::Automata sugar for Mojolicious

=head1 SYNOPSIS

    package
    MyApp;

    use strict;
    use warnings;

    use base 'MojoliciousX::Automata';

    # You get this by default
    #__PACKAGE__->attr(automata => (default => sub { MojoX::Automata->new }));

    # You get this by default
    #sub dispatch {
    #    my ($self, $c) = @_;

    #    # Run automata
    #    $self->automata->run($c);
    #}

    ...

    # You get same thing but with default dispatch method and already created
    # attribute 'automata' that is holding MojoX::Automata object

=head1 METHODS

=head2 C<dispatch>

This is an overriden mojolicious dispatch.

=head1 DESCRIPTION

L<MojoliciousX::Automata> is a Mojolicious finite automata dispatching
mechanizm. It adds some sugar, so you don't have to create attribute that will
hold MojoX::Automata object and you get the default dispatch method that calls
automata->run also.

For more info see MojoX::Automata documentation.
