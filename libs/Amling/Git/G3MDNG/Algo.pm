package Amling::Git::G3MDNG::Algo;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::Git;
use Amling::Git::G3MDNG::Utils;

sub diff3_blocks
{
    my $blocks = shift;

    my $new_blocks = [];
    for my $block (@$blocks)
    {
        my ($type, @rest) = @$block;

        if(0)
        {
        }
        elsif($type eq 'RESOLVED')
        {
            my ($chunk) = @rest;
            push @$new_blocks, ['RESOLVED', $chunk];
        }
        elsif($type eq 'CONFLICT')
        {
            my ($lhs_chunks, $mhs_chunks, $rhs_chunks) = @rest;
            push @$new_blocks, @{diff3($lhs_chunks, $mhs_chunks, $rhs_chunks)};
        }
        else
        {
            die;
        }
    }

    if(!@$new_blocks)
    {
        # we leave as an all-empty conflict to avoid trying to do an empty
        # splice (!)
        return
        [
            [
                'CONFLICT',
                [],
                [],
                [],
            ],
        ];
    }

    return $new_blocks;
}

my $include_resolved = undef;
sub _include_resolved
{
    if(!defined($include_resolved))
    {
        $include_resolved = (system('sh', '-c', 'exec 2> /dev/null "$@"', '-', 'git', 'merge-file', '--include-resolved', '-p', '/dev/null', '/dev/null', '/dev/null') == 0);
        if(!$include_resolved)
        {
            warn 'git merge-file does not support --include-resolved, falling back to lossy diff3'
        }
    }
    return $include_resolved;
}

sub diff3
{
    my $lhs_chunks = shift;
    my $mhs_chunks = shift;
    my $rhs_chunks = shift;

    my ($is_encoded, $lhs_lines, $mhs_lines, $rhs_lines) = @{Amling::Git::G3MDNG::Utils::encode_chunks($lhs_chunks, $mhs_chunks, $rhs_chunks)};

    my $old_blocks = Amling::Git::G3MD::Resolver::Git::invoke_gmf($lhs_lines, $mhs_lines, $rhs_lines, _include_resolved() ? ['--include-resolved'] : []);

    my $new_blocks = [];
    for my $old_block (@$old_blocks)
    {
        my ($type, @rest) = @$old_block;

        if(0)
        {
        }
        elsif($type eq 'LINE')
        {
            my ($old_line) = @rest;
            my $new_chunk = Amling::Git::G3MDNG::Utils::decode_chunks($is_encoded, [$old_line])->[0]->[0];
            push @$new_blocks,
            [
                'RESOLVED',
                $new_chunk,
            ];
        }
        elsif($type eq 'CONFLICT')
        {
            my ($lhs_old_title, $lhs_old_lines, $mhs_old_title, $mhs_old_lines, $rhs_old_title, $rhs_old_lines) = @rest;
            my ($lhs_new_chunks, $mhs_new_chunks, $rhs_new_chunks) = @{Amling::Git::G3MDNG::Utils::decode_chunks($is_encoded, $lhs_old_lines, $mhs_old_lines, $rhs_old_lines)};
            push @$new_blocks,
            [
                'CONFLICT',
                $lhs_new_chunks,
                $mhs_new_chunks,
                $rhs_new_chunks,
            ];
        }
        else
        {
            die;
        }
    }

    return $new_blocks;
}

1;
