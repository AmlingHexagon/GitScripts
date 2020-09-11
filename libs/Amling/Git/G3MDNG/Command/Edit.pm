package Amling::Git::G3MDNG::Command::Edit;

use strict;
use warnings;

use Amling::Git::G3MDNG::Command::BaseReplace;
use Amling::Git::G3MDNG::Utils;
use Amling::Git::Utils;
use File::Temp ('tempfile');

use base ('Amling::Git::G3MDNG::Command::BaseReplace');

sub handle3
{
    my $class = shift;
    my $loop = shift;
    my $rest = shift;

    my ($lhs_chunks, $mhs_chunks, $rhs_chunks) = @$rest;

    my ($is_encoded, $lhs_lines, $mhs_lines, $rhs_lines) = @{Amling::Git::G3MDNG::Utils::encode_chunks($lhs_chunks, $mhs_chunks, $rhs_chunks)};

    my ($fh1, $fn1) = tempfile('SUFFIX' => '.lhs.conflict');
    my ($fh2, $fn2) = tempfile('SUFFIX' => '.mhs.conflict');
    my ($fh3, $fn3) = tempfile('SUFFIX' => '.rhs.conflict');

    for my $tuple ([$fh1, $fn1, $lhs_lines], [$fh2, $fn2, $mhs_lines], [$fh3, $fn3, $rhs_lines])
    {
        my ($fh, $fn, $lines) = @$tuple;
        for my $line (@$lines)
        {
            print $fh "$line\n";
        }
        close($fh) || die "Cannot close temp file $fn: $!";
    }

    system('vim', '-O', $fn1, $fn2, $fn3) && die "Edit of files bailed?";

    my $lhs_lines2 = Amling::Git::Utils::slurp($fn1);
    my $mhs_lines2 = Amling::Git::Utils::slurp($fn2);
    my $rhs_lines2 = Amling::Git::Utils::slurp($fn3);

    unlink($fn1) || die "Cannot unlink temp file $fn1: $!";
    unlink($fn2) || die "Cannot unlink temp file $fn2: $!";
    unlink($fn3) || die "Cannot unlink temp file $fn3: $!";

    my ($lhs_chunks2, $mhs_chunks2, $rhs_chunks2) = @{Amling::Git::G3MDNG::Utils::decode_chunks($is_encoded, $lhs_lines2, $mhs_lines2, $rhs_lines2)};

    return
    [
        [
            'CONFLICT',
            $lhs_chunks2,
            $mhs_chunks2,
            $rhs_chunks2,
        ],
    ];
}

Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['edit', 'e']));

1;
