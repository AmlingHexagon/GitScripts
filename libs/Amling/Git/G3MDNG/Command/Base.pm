package Amling::Git::G3MDNG::Command::Base;

use strict;
use warnings;

sub new
{
    my $class = shift;
    my $aliases = shift;

    my $this =
    {
        'ALIASES' => $aliases,
    };

    bless $this, $class;

    return $this;
}

sub args_regex
{
    return qr//;
}

sub args_string
{
    my $this = shift;
    my @match = @_;

    return join(' ', @match);
}

sub alias_regex
{
    my $this = shift;
    my $alias = shift;

    my $args_regex = $this->args_regex();
    return qr/^\s*\Q$alias\E\s*$args_regex\s*$/;
}

sub handle
{
    my $this = shift;
    my $loop = shift;
    my $state = shift;
    my $line = shift;

    for my $alias (@{$this->{'ALIASES'}})
    {
        my $regex = $this->alias_regex($alias);
        if($line =~ $regex)
        {
            # Sigh, perl, so dumb.  I could find no less silly way to get all
            # capture args and importantly an empty array when there were no
            # capture args.
            my @match = map { substr($line, $-[$_], $+[$_] - $-[$_]) } (1..$#-);
            return $this->handle2($loop, $state, @match);
        }
    }

    return 0;
}

1;
