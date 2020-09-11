package Amling::Git::G3MDNG::Command;

use strict;
use warnings;

my @commands;

sub add_command
{
    my $command = shift;

    push @commands, $command;
}

sub handle
{
    my $loop = shift;
    my $state = shift;
    my $line = shift;

    for my $command (@commands)
    {
        return if($command->handle($loop, $state, $line));
    }

    print "?\n";
}

use Amling::Git::G3MDNG::Command::CharacterSplit;
use Amling::Git::G3MDNG::Command::Characters;
use Amling::Git::G3MDNG::Command::Clowns;
use Amling::Git::G3MDNG::Command::Diff3;
use Amling::Git::G3MDNG::Command::Edit;
use Amling::Git::G3MDNG::Command::Indents;
use Amling::Git::G3MDNG::Command::Merge;
use Amling::Git::G3MDNG::Command::Nav;
use Amling::Git::G3MDNG::Command::NavConflict;
use Amling::Git::G3MDNG::Command::Sort;
use Amling::Git::G3MDNG::Command::Split;
use Amling::Git::G3MDNG::Command::StateMethods;
use Amling::Git::G3MDNG::Command::Words;

1;
