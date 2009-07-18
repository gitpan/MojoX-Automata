package Foo;
use base 'Mojo::Base';

__PACKAGE__->attr('key');

sub run {
}

package Bar;
use base 'Mojo::Base';

sub run {
}

package main;

use strict;
use warnings;

use Test::More tests => 2;

use_ok('MojoX::Automata');

my $automata = MojoX::Automata->new();

$automata->state('foo')->handler('Foo')->to('bar');
$automata->state('bar')->handler('Bar')->to('foo');

# start -> end
eval {$automata->run; };
ok($@);
