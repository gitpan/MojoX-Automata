package MyApp::Automata::DetectLang;

use strict;
use warnings;

use base 'Mojo::Base';

__PACKAGE__->attr('languages', default => sub { [] });

sub run {
    my $self = shift;
    my ($c) = @_;

    my $language;

    if (my $path = $c->tx->req->url->path) {
        my $part = $path->parts->[0];

        if ($part && grep { $part eq $_ } @{$self->languages}) {
            shift @{$path->parts};

            $language = $part;

            $c->app->log->debug("Found language $language in url");
        }
    }

    unless ($language) {
        if (my $accept_language = $c->req->headers->header('accept-language')) {
            if (my @languages = split(',', $accept_language)) {
                foreach my $lang (@languages) {
                    ($lang) = ($lang =~ m/^(..)/);
                    if (grep { $_ eq $lang} @{$self->languages}) {
                        $language = $lang;
                        $c->app->log->debug("Found language $language in Accept-Language");
                        last;
                    }
                }
            }
        }
    }

    $language ||= 'en';

    $c->languages([$language]);
    $c->app->log->debug("Setting $language language");

    return 1;
}

1;
