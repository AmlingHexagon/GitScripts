package Amling::Git::G3MDNG::Command::Indents;

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

    $lhs_chunks = rewrite($lhs_chunks);
    return undef unless(defined($lhs_chunks));
    $mhs_chunks = rewrite($mhs_chunks);
    return undef unless(defined($mhs_chunks));
    $rhs_chunks = rewrite($rhs_chunks);
    return undef unless(defined($rhs_chunks));

    my $blocks =
    [
        [
            'CONFLICT',
            $lhs_chunks,
            $mhs_chunks,
            $rhs_chunks,
        ]
    ];

    my $text = $loop->run_file('<recursive>', $blocks);

    if(!defined($text))
    {
        print "Recursive resolution failed, refusing!\n";
        return undef;
    }

    return unrewrite([split("\n", $text)]);
}

sub rewrite
{
    my $chunks = shift;

    my @lines = ();
    my @chomp = ();
    for(my $i = 0; $i < @$chunks; ++$i)
    {
        my $chunk = $chunks->[$i];
        if($chunk =~ s/\n$//)
        {
        }
        elsif($i == scalar(@$chunk) - 1)
        {
            @chomp = ("CHOMP\n");
        }
        else
        {
            return undef;
        }
        if($chunk =~ /\n/)
        {
            return undef;
        }
        push @lines, $chunk;
    }

    my $ret = [];
    my $indent = 0;
    my $pending_blanks = 0;
    for my $chunk (@$chunks)
    {
        if($chunk eq '')
        {
            ++$pending_blanks;
            next;
        }
        $chunk =~ /^( *)(.*)$/s || die;
        my $indent1 = length($1);
        my $line = $2;

        while($indent > $indent1)
        {
            push @$ret, "DEINDENT\n";
            --$indent;
        }
        while($pending_blanks)
        {
            push @$ret, "BLANK\n";
            --$pending_blanks;
        }
        while($indent < $indent1)
        {
            push @$ret, "INDENT\n";
            ++$indent;
        }

        push @$ret, "LINE: $line\n";
    }

    while($indent > 0)
    {
        push @$ret, "DEINDENT\n";
        --$indent;
    }
    while($pending_blanks)
    {
        push @$ret, "BLANK\n";
        --$pending_blanks;
    }

    push @$ret, @chomp;

    return $ret;
}

sub unrewrite
{
    my $lines = shift;

    my @resolved;
    my $indent = 0;
    for my $line (@$lines)
    {
        if(0)
        {
        }
        elsif($line eq 'INDENT')
        {
            ++$indent;
        }
        elsif($line eq 'DEINDENT')
        {
            --$indent;
            if($indent < 0)
            {
                print "Recursive resolution invalid (unmatched DEINDENT), refusing!\n";
                return undef;
            }
        }
        elsif($line eq 'CHOMP')
        {
            if(!@resolved)
            {
                print "Recursive resolution invalid (starting CHOMP), refusing!\n";
                return undef;
            }
            chomp $resolved[-1];
        }
        elsif($line eq 'BLANK')
        {
            push @resolved, "\n";
        }
        elsif($line =~ /^LINE: (.*)$/)
        {
            push @resolved, (" " x $indent) . "$1\n";
        }
        else
        {
            print "Recursive resolution invalid (nonsense line '$line'), refusing!\n";
            return undef;
        }
    }
    if($indent != 0)
    {
        print "Recursive resolution invalid (indent at end $indent), refusing!\n";
        return undef;
    }

    return [map { ['RESOLVED', $_] } @resolved];
}

Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['indents', 'indent', 'i']));

1;
