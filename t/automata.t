package FilterStart;
use base 'Mojo::Base';

__PACKAGE__->attr('key');

sub run {
    my ($self, $c) = @_;
    if ($c->stash->{$self->key} && !$c->stash->{a}) {
        return 1;
    }
    return 0;
}

package FilterEnd;
use base 'Mojo::Base';

sub run {
    my ($self, $c) = @_;
    $c->stash->{last} = 1;
}

package main;

use strict;
use warnings;

use Test::More tests => 5;
use MojoX::Context;

use_ok('MojoX::Automata');

my $c = MojoX::Context->new();

my $automata = MojoX::Automata->new();

# Preloading class with args
$automata->state('start')->handler(FilterStart => (key => 'foo'))
  ->to(0 => 'end', 1 => 'sub');

# Subroutine
$automata->state('sub')
  ->handler(sub { shift->stash->{a} = 1 })->to('end');

# Object
$automata->state('end')->handler(FilterEnd->new);

# start -> end
$automata->run($c);
ok(not defined $c->stash->{a});
is($c->stash->{last}, 1);

# start -> sub -> end
$c->stash->{foo} = 1;
$automata->run($c);
is($c->stash->{a},    1);
is($c->stash->{last}, 1);
