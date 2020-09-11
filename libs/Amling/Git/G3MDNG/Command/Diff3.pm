package Amling::Git::G3MDNG::Command::Diff3;

use strict;
use warnings;

use Amling::Git::G3MDNG::Algo;
use Amling::Git::G3MDNG::Command::BaseReplace;

use base ('Amling::Git::G3MDNG::Command::BaseReplace');

sub handle3
{
    my $class = shift;
    my $loop = shift;
    my $rest = shift;

    my ($lhs_chunks, $mhs_chunks, $rhs_chunks) = @$rest;

    return Amling::Git::G3MDNG::Algo::diff3($lhs_chunks, $mhs_chunks, $rhs_chunks);
}


Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['diff3', '']));

1;
