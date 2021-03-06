package Amling::Git::G3MD::Resolver::RightBack;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::BasePeel;

use base ('Amling::Git::G3MD::Resolver::BasePeel');

sub hside
{
    return 'right';
}

sub vside
{
    return 'back';
}

sub peel_pair
{
    my $class = shift;
    my $lhs_lines = shift;
    my $mhs_lines = shift;
    my $rhs_lines = shift;

    return [pop @$mhs_lines, pop @$rhs_lines];
}

Amling::Git::G3MD::Resolver::add_resolver(__PACKAGE__);

1;
