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

package FilterA;
use base 'Mojo::Base';

sub run {
    my ($self, $c) = @_;

    $c->stash->{a} = 1;
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

use Test::More tests => 4;
use MojoX::Context;

use_ok('MojoX::Automata');

my $c = MojoX::Context->new();

my $automata = MojoX::Automata->new();

$automata->register('s' => 'FilterStart', key => 'foo');
$automata->register('a' => 'FilterA');
$automata->register('e' => 'FilterEnd');

$automata->start('s')->end('e');

$automata->add_path('s', 0 => 'e', 1 => 'a');
$automata->add_path('a' => 's');

$automata->run($c);
ok(not defined $c->stash->{a});

$c->stash->{foo} = 1;
$automata->run($c);
is($c->stash->{a},    1);
is($c->stash->{last}, 1);
