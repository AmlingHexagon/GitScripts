package Amling::Git::G3MDNG::Loop;

use strict;
use warnings;

use Amling::Git::G3MDNG::Command;
use Amling::Git::G3MDNG::State;
use Amling::Git::G3MDNG::Utils;

sub new
{
    my $class = shift;

    my $this =
    {
    };

    bless $this, $class;

    return $this;
}

sub options
{
    return
    (
    );
}

sub run
{
    my $this = shift;
    my $files = shift;

    # RAGE
    local @ARGV = ();

    for my $file (sort(keys(%$files)))
    {
        my $blocks = $files->{$file}->{'blocks'};
        my $save = $files->{$file}->{'save'};

        $this->run_file($file, $blocks, $save);
    }
}

sub run_file
{
    my $this = shift;
    my $file = shift;
    my $blocks0 = shift;
    my $save = shift;

    my $state = Amling::Git::G3MDNG::State->new($blocks0);

    while(1)
    {
        if($state->is_dirty())
        {
            my $pos = $state->find_conflict();
            last unless(defined($pos));

            $state->mark_clean();
            $state->move($pos);
        }

        #use Data::Dumper; print STDERR Dumper($state->{'BLOCKS'});

        my $block = $state->current_block();

        my ($type, @rest) = @$block;
        if(0)
        {
        }
        elsif($type eq 'RESOLVED')
        {
            my ($chunk) = @rest;

            my ($is_encoded, $lines) = @{Amling::Git::G3MDNG::Utils::encode_chunks([$chunk])};

            print "Resolved:\n";
            print "   [[[[[[[\n";
            print "   $_\n" for(@$lines);
            print "   ]]]]]]]\n";
        }
        elsif($type eq 'CONFLICT')
        {
            my ($lhs_title, $lhs_chunks, $mhs_title, $mhs_chunks, $rhs_title, $rhs_chunks) = @rest;

            my ($is_encoded, $lhs_lines, $mhs_lines, $rhs_lines) = @{Amling::Git::G3MDNG::Utils::encode_chunks($lhs_chunks, $mhs_chunks, $rhs_chunks)};

            print "Conflict:\n";
            print "   <<<<<<< $lhs_title\n";
            print "   $_\n" for(@$lhs_lines);
            print "   ||||||| $mhs_title\n";
            print "   $_\n" for(@$mhs_lines);
            print "   =======\n";
            print "   $_\n" for(@$rhs_lines);
            print "   >>>>>>> $rhs_title\n";
        }
        else
        {
            die;
        }

        print "> ";
        my $ans = <>;
        chomp $ans;

        Amling::Git::G3MDNG::Command::handle($state, $ans);
    }

    my $text = $state->require_auto_resolve();

    print "Successfully resolved $file.\n";

    $save->($text);
}

1;
