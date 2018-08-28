package Amling::Git::G3MDNG::Utils;

use strict;
use warnings;

use Digest;
use JSON;

my $json = JSON->new();
$json->allow_nonref();

sub encode_chunks
{
    my @chunkses = @_;

    my $is_encoded = 0;
    my $unencoded_lineses = [];
    DETECT_NONLINE:
    for my $chunks (@chunkses)
    {
        my $unencoded_lines = [];
        for my $chunk (@$chunks)
        {
            if($chunk =~ /^(.*)\n$/)
            {
                push @$unencoded_lines, $1;
            }
            else
            {
                $is_encoded = 1;
                last DETECT_NONLINE;
            }
        }
        push @$unencoded_lineses, $unencoded_lines;
    }
    if(!$is_encoded)
    {
        return [0, @$unencoded_lineses];
    }

    my $lineses = [];
    for my $chunks (@chunkses)
    {
        my $lines = [];
        for my $chunk (@$chunks)
        {
            push @$lines, encode_chunk($chunk);
        }
        push @$lineses, $lines;
    }

    return [1, @$lineses];
}

sub decode_chunks
{
    my $is_encoded = shift;
    my @lineses = @_;

    my $chunkses = [];
    for my $lines (@lineses)
    {
        my $chunks = [];
        for my $line (@$lines)
        {
            push @$chunks, ($is_encoded ? decode_chunk($line) : "$line\n");
        }
        push @$chunkses, $chunks;
    }

    return $chunkses;
}

sub encode_chunk
{
    my $chunk = shift;

    $chunk =~ s/\\/\\\\/g;
    $chunk =~ s/\n/\\n/g;
    $chunk =~ s/\r/\\r/g;

    return $chunk;
}

sub decode_chunk
{
    my $line = shift;

    $line =~ s/\\n/\n/g;
    $line =~ s/\\r/\r/g;
    $line =~ s/\\\\/\\/g;

    return $line;
}

sub auto_resolve_block
{
    my $block = shift;

    my ($type, @rest) = @$block;

    if($type eq 'RESOLVED')
    {
        my ($chunk) = @rest;
        return $chunk;
    }

    if($type eq 'CONFLICT')
    {
        my ($lhs_chunks, $mhs_chunks, $rhs_chunks) = @rest;

        my $lhs_text = join('', @$lhs_chunks);
        my $mhs_text = join('', @$mhs_chunks);
        my $rhs_text = join('', @$rhs_chunks);

        my $text = auto_resolve_text($lhs_text, $mhs_text, $rhs_text);
        return $text if(defined($text));
    }

    return undef;
}

sub auto_resolve_text
{
    my $lhs_text = shift;
    my $mhs_text = shift;
    my $rhs_text = shift;

    return $rhs_text if($lhs_text eq $mhs_text);
    return $lhs_text if($mhs_text eq $rhs_text);
    return $lhs_text if($lhs_text eq $rhs_text);

    return undef;
}

sub hash
{
    my $r = shift;

    my $sha1 = Digest->new("SHA-1");

    $sha1->add($json->encode($r));

    return $sha1->hexdigest();
}

1;
