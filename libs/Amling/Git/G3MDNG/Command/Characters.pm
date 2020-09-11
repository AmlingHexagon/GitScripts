package Amling::Git::G3MDNG::Command::Characters;

use strict;
use warnings;

use Amling::Git::G3MDNG::Command::BaseReplace;

use base ('Amling::Git::G3MDNG::Command::BaseReplace');

sub handle3
{
    my $this = shift;
    my $loop = shift;
    my $rest = shift;

    my ($lhs_chunks, $mhs_chunks, $rhs_chunks) = @$rest;

    return
    [
        [
            'CONFLICT',
            [map { split(//, $_) } @$lhs_chunks],
            [map { split(//, $_) } @$mhs_chunks],
            [map { split(//, $_) } @$rhs_chunks],
        ],
    ];
}

Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['characters', 'character', 'chars', 'char', 'c']));

1;
