package Amling::Git::G3MDNG::Command::Sort;

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

    my %ct;
    for my $pair ([$lhs_chunks, 1], [$rhs_chunks, 1], [$mhs_chunks, -1])
    {
        my ($chunks, $delta) = @$pair;
        for my $chunk (@$chunks)
        {
            return undef unless($chunk =~ /^(.*)\n$/);
            my $line = $1;
            ($ct{$line} ||= 0) += $delta;
        }
    }

    my @lines = grep { $ct{$_} > 0 } (sort(keys(%ct)));

    # ouch, can't splice empty list!
    return [['RESOLVED', '']] unless(@lines);

    return [map { ['RESOLVED', "$_\n"] } @lines];
}

Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['sort', 's']));

1;
