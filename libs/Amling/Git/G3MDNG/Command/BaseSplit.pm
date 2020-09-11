package Amling::Git::G3MDNG::Command::BaseSplit;

use strict;
use warnings;

use Amling::Git::G3MDNG::Command::BaseReplace;

use base ('Amling::Git::G3MDNG::Command::BaseReplace');

sub args_regex
{
    return qr/\s(-?\d+|\*)(?:\s+(-?\d+|\*)\s+(-?\d+|\*))?/;
}

sub handle3
{
    my $this = shift;
    my $loop = shift;
    my $rest = shift;
    my $lhs_split = shift;
    my $mhs_split = shift;
    my $rhs_split = shift;

    my ($lhs_chunks, $mhs_chunks, $rhs_chunks) = @$rest;

    $mhs_split = $lhs_split unless(defined($mhs_split));
    $rhs_split = $lhs_split unless(defined($rhs_split));

    my $lhs_len = $this->compute_len($lhs_chunks);
    my $mhs_len = $this->compute_len($mhs_chunks);
    my $rhs_len = $this->compute_len($rhs_chunks);

    $lhs_split = _interpret_split($lhs_len, $lhs_split);
    $mhs_split = _interpret_split($mhs_len, $mhs_split);
    $rhs_split = _interpret_split($rhs_len, $rhs_split);

    return undef unless(0 <= $lhs_split && $lhs_split <= $lhs_len);
    return undef unless(0 <= $mhs_split && $mhs_split <= $mhs_len);
    return undef unless(0 <= $rhs_split && $rhs_split <= $rhs_len);

    my ($lhs_chunks2a, $lhs_chunks2b) = $this->split_chunks($lhs_chunks, $lhs_split);
    my ($mhs_chunks2a, $mhs_chunks2b) = $this->split_chunks($mhs_chunks, $mhs_split);
    my ($rhs_chunks2a, $rhs_chunks2b) = $this->split_chunks($rhs_chunks, $rhs_split);

    return
    [
        [
            'CONFLICT',
            $lhs_chunks2a,
            $mhs_chunks2a,
            $rhs_chunks2a,
        ],
        [
            'CONFLICT',
            $lhs_chunks2b,
            $mhs_chunks2b,
            $rhs_chunks2b,
        ],
    ];
}

sub _interpret_split
{
    my $len = shift;
    my $split = shift;

    return $len if($split eq '*');
    return ($len - $1) if($split =~ /^-(\d+)$/);
    return $split;
}

1;
