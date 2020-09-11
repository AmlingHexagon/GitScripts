package Amling::Git::G3MDNG::Command::Words;

use strict;
use warnings;

use Amling::Git::G3MDNG::Command::BaseReplace;

use base ('Amling::Git::G3MDNG::Command::BaseReplace');

sub new
{
    my $class = shift;
    my $aliases = shift;
    my $class2 = shift;

    my $this = $class->SUPER::new($aliases);

    $this->{'CLASS2'} = $class2;

    return $this;
}

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
            [map { @{$this->split_words($_)} } @$lhs_chunks],
            [map { @{$this->split_words($_)} } @$mhs_chunks],
            [map { @{$this->split_words($_)} } @$rhs_chunks],
        ],
    ];
}

sub split_words
{
    my $this = shift;
    my $chunk = shift;

    my $class2 = $this->{'CLASS2'};

    my $nchunks = [];
    my $wip = undef;
    for(my $i = 0; $i < length($chunk); ++$i)
    {
        my $c = substr($chunk, $i, 1);
        my $ctype;
        if($c =~ /\s/)
        {
            $ctype = 0;
        }
        elsif(index($class2, $c) == -1)
        {
            $ctype = 1;
        }
        else
        {
            $ctype = 2;
        }

        if(!$wip)
        {
            $wip = [$ctype, ''];
        }
        elsif($wip->[0] != $ctype)
        {
            push @$nchunks, $wip->[1];
            $wip = [$ctype, ''];
        }

        $wip->[1] .= $c;
    }

    if(defined($wip))
    {
        push @$nchunks, $wip->[1];
    }

    return $nchunks;
}

Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['words', 'word', 'w'], 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'));
Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['Words', 'Word', 'W'], ''));

1;
