package Amling::Git::G3MDNG::State;

use strict;
use warnings;

use Amling::Git::G3MDNG::Algo;
use Amling::Git::G3MDNG::Utils;
use File::Temp ('tempfile');

my $hash = \&Amling::Git::G3MDNG::Utils::hash;

sub new
{
    my $class = shift;
    my $blocks = shift;

    my $this =
    {
        'BLOCKS' => $blocks,
        'UNDO' => [],
        'REDO' => [],
        'POS' => 0,
        'DIRTY' => 1,
    };

    bless $this, $class;

    return $this;
}

sub merge
{
    my $this = shift;
    my $s = shift;
    my $e = shift;

    my $blocks = $this->{'BLOCKS'};
    die unless(0 <= $s && $s <= $e && $e <= @$blocks);

    my $merged_lhs_chunks = [];
    my $merged_mhs_chunks = [];
    my $merged_rhs_chunks = [];
    for(my $i = $s; $i < $e; ++$i)
    {
        my $block = $blocks->[$i];
        my ($type, @rest) = @$block;
        if(0)
        {
        }
        elsif($type eq 'RESOLVED')
        {
            my ($chunk) = @rest;
            push @$merged_lhs_chunks, $chunk;
            push @$merged_mhs_chunks, $chunk;
            push @$merged_rhs_chunks, $chunk;
        }
        elsif($type eq 'CONFLICT')
        {
            my ($lhs_chunks, $mhs_chunks, $rhs_chunks) = @rest;
            push @$merged_lhs_chunks, @$lhs_chunks;
            push @$merged_mhs_chunks, @$mhs_chunks;
            push @$merged_rhs_chunks, @$rhs_chunks;
        }
        else
        {
            die;
        }
    }

    my $merged_block =
    [
        'CONFLICT',
        $merged_lhs_chunks,
        $merged_mhs_chunks,
        $merged_rhs_chunks,
    ];

    $this->splice($s, $e, [$merged_block], 'merge', 1);
}

sub find_conflict
{
    my $this = shift;
    my $dir = shift || 1;
    my $offset = shift || 0;

    my $blocks = $this->{'BLOCKS'};
    my $pos = $this->{'POS'};

    my $n = @$blocks;
    for(my $i = 0; $i < $n; ++$i)
    {
        my $pos2 = ($pos + ($offset + $i) * $dir) % $n;
        if(!defined(Amling::Git::G3MDNG::Utils::auto_resolve_block($blocks->[$pos2])))
        {
            return $pos2;
        }
    }

    return undef;
}

sub require_auto_resolve
{
    my $this = shift;

    my @texts;
    for my $block (@{$this->{'BLOCKS'}})
    {
        my $text = Amling::Git::G3MDNG::Utils::auto_resolve_block($block);
        die unless(defined($text));

        push @texts, $text;
    }

    return join('', @texts);
}

sub mark_dirty
{
    my $this = shift;

    $this->{'DIRTY'} = 1;
}

sub is_dirty
{
    my $this = shift;

    return $this->{'DIRTY'};
}

sub mark_clean
{
    my $this = shift;

    $this->{'DIRTY'} = 0;
}

sub move
{
    my $this = shift;
    my $pos = shift;

    $this->{'POS'} = $pos;
}

sub move_delta
{
    my $this = shift;
    my $delta = shift;

    $this->{'POS'} += $delta;
    $this->{'POS'} %= scalar(@{$this->{'BLOCKS'}});
}

sub blocks
{
    my $this = shift;

    return $this->{'BLOCKS'};
}

sub old_blockses
{
    my $this = shift;

    return [map { $_->[2] } @{$this->{'UNDO'}}];
}

sub memory_edits
{
    my $this = shift;

    my $edits = [map { $_->[3] } @{$this->{'UNDO'}}];
    $edits = [grep { $_->{'MEMORIZABLE'} } @$edits];
    $edits = [map { @{edit_symmetries($_)} } @$edits];

    return $edits;
}

sub current_pos
{
    my $this = shift;

    return $this->{'POS'};
}

sub current_block
{
    my $this = shift;

    return $this->{'BLOCKS'}->[$this->{'POS'}];
}

sub splice
{
    my $this = shift;
    my $s = shift;
    my $e = shift;
    my $new_blocks = shift;
    my $desc = shift;
    my $memorizable = shift;

    # We can't handle this case (e.g.  may leave with no blocks left, nowhere
    # to put cursor!).  If we ever invent deletion (goodness, why) maybe we'll
    # insert an empty block instead or something.
    die unless(@$new_blocks);

    my $blocks = $this->{'BLOCKS'};
    my $pos = $this->{'POS'};

    my $blocks2 = [@$blocks];
    my $old_blocks = [splice @$blocks2, $s, $e - $s, @$new_blocks];

    my $pos2;
    if($pos < $s)
    {
        # we were strictly before the edit, stay where we are
        $pos2 = $pos;
    }
    elsif($pos >= $e)
    {
        # we were strictly after the edit, adjust for edit resize
        $pos2 = $s + scalar(@$new_blocks) + ($pos - $e);
    }
    else
    {
        # we were in the edit itself, for now let's not worry about mapping and
        # just put ourselves at the top of the new blocks
        $pos2 = $s;
    }

    my $edit =
    {
        'IN' => $old_blocks,
        'OUT' => $new_blocks,
        'DESC' => $desc,
        'START' => $s,
        'MEMORIZABLE' => $memorizable,
    };

    if($hash->($old_blocks) eq $hash->($new_blocks))
    {
        print "Refused NOP " . describe_edit($edit) . "\n";
        return 0;
    }

    push @{$this->{'UNDO'}}, [$pos, $pos2, $blocks, $edit];
    $this->{'REDO'} = [];

    $this->{'BLOCKS'} = $blocks2;
    $this->{'POS'} = $pos2;

    print "Applied " . describe_edit($edit) . ".\n";
    return 1;
}

sub undo
{
    my $this = shift;

    my $last = pop @{$this->{'UNDO'}};
    return 0 unless($last);

    my ($pos_before, $pos_after, $blocks_before, $edit) = @$last;
    push @{$this->{'REDO'}}, [$pos_before, $pos_after, $this->{'BLOCKS'}, $edit];

    $this->{'POS'} = $pos_before;
    $this->{'BLOCKS'} = $blocks_before;

    print "Undid " . describe_edit($edit) . ".\n";

    return 1;
}

sub redo
{
    my $this = shift;

    my $next = pop @{$this->{'REDO'}};
    return 0 unless($next);

    my ($pos_before, $pos_after, $blocks_after, $edit) = @$next;
    push @{$this->{'UNDO'}}, [$pos_before, $pos_after, $this->{'BLOCKS'}, $edit];

    $this->{'POS'} = $pos_after;
    $this->{'BLOCKS'} = $blocks_after;

    print "Redid " . describe_edit($edit) . ".\n";

    return 1;
}

sub describe_edit
{
    my $edit = shift;

    my $in_blocks = $edit->{'IN'};
    my $out_blocks = $edit->{'OUT'};
    my $desc = $edit->{'DESC'};
    my $s = $edit->{'START'};

    return "$desc [$s, " . ($s + scalar(@$in_blocks)) . ") -> [$s, " . ($s + scalar(@$out_blocks)) . ")";
}

sub edit_symmetries
{
    my $edit = shift;

    return [$edit, flip_edit($edit)];
}

sub flip_edit
{
    my $edit = shift;

    return
    {
        'IN' => flip_blocks($edit->{'IN'}),
        'OUT' => flip_blocks($edit->{'OUT'}),
        'DESC' => "reversed " . $edit->{'DESC'},
    };
}

sub flip_blocks
{
    my $blocks = shift;

    return [map { flip_block($_) } @$blocks];
}

sub flip_block
{
    my $block = shift;

    my ($type, @rest) = @$block;
    if($type eq 'RESOLVED')
    {
        my ($chunk) = @rest;
        return ['RESOLVED', $chunk];
    }
    if($type eq 'CONFLICT')
    {
        my ($lhs_chunks, $mhs_chunks, $rhs_chunks) = @rest;
        return ['CONFLICT', $rhs_chunks, $mhs_chunks, $lhs_chunks];
    }
    die;
}

sub maybe_auto_diff3
{
    my $this = shift;
    my $s = shift;
    my $e = shift;

    my $all_blocks = $this->{'BLOCKS'};
    my $old_blocks = [@$all_blocks[$s..($e - 1)]];
    my $new_blocks = Amling::Git::G3MDNG::Algo::diff3_blocks($old_blocks);

    return if($hash->($old_blocks) eq $hash->($new_blocks));

    while(1)
    {
        print "Auto diff3 possible, apply? [Y/n/e]\n";
        print "> ";
        my $ans = <>;
        chomp $ans;
        $ans = lc($ans);

        if($ans eq 'y' || $ans eq '')
        {
            $this->splice($s, $e, $new_blocks, "auto diff3", 1);
            return;
        }

        if($ans eq 'n')
        {
            return;
        }

        if($ans eq 'e')
        {
            my ($fh1, $fn1) = tempfile('SUFFIX' => '.old');
            my ($fh2, $fn2) = tempfile('SUFFIX' => '.new');

            my @all_chunkses;
            for my $blocks ($old_blocks, $new_blocks)
            {
                for my $block (@$blocks)
                {
                    my ($type, @rest) = @$block;
                    if(0)
                    {
                    }
                    elsif($type eq 'RESOLVED')
                    {
                        my ($chunk) = @rest;
                        push @all_chunkses, [$chunk];
                    }
                    elsif($type eq 'CONFLICT')
                    {
                        my ($lhs_chunks, $mhs_chunks, $rhs_chunks) = @rest;
                        push @all_chunkses, $lhs_chunks, $mhs_chunks, $rhs_chunks;
                    }
                    else
                    {
                        die;
                    }
                }
            }

            my ($is_encoded, @all_lineses) = @{Amling::Git::G3MDNG::Utils::encode_chunks(@all_chunkses)};

            for my $tuple ([$fh1, $fn1, $old_blocks], [$fh2, $fn2, $new_blocks])
            {
                my ($fh, $fn, $blocks) = @$tuple;
                for my $block (@$blocks)
                {
                    my ($type, @rest) = @$block;
                    if(0)
                    {
                    }
                    elsif($type eq 'RESOLVED')
                    {
                        my ($chunk) = @rest;
                        my $lines = shift @all_lineses;
                        for my $line (@$lines)
                        {
                            print $fh "$line\n";
                        }
                    }
                    elsif($type eq 'CONFLICT')
                    {
                        my ($lhs_chunks, $mhs_chunks, $rhs_chunks) = @rest;
                        my $lhs_lines = shift @all_lineses;
                        my $mhs_lines = shift @all_lineses;
                        my $rhs_lines = shift @all_lineses;
                        print $fh "<<<<<<<\n";
                        for my $line (@$lhs_lines)
                        {
                            print $fh "$line\n";
                        }
                        print $fh "|||||||\n";
                        for my $line (@$mhs_lines)
                        {
                            print $fh "$line\n";
                        }
                        print $fh "=======\n";
                        for my $line (@$rhs_lines)
                        {
                            print $fh "$line\n";
                        }
                        print $fh ">>>>>>>\n";
                    }
                    else
                    {
                        die;
                    }
                }
                close($fh) || die "Cannot close temp file $fn: $!";
            }

            system('vimdiff', '-R', $fn1, $fn2) && die "Edit of files bailed?";

            unlink($fn1) || die "Cannot unlink temp file $fn1: $!";
            unlink($fn2) || die "Cannot unlink temp file $fn2: $!";

            next;
        }

        print "?\n";
    }
}

1;
