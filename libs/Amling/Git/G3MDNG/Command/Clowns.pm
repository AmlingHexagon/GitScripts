package Amling::Git::G3MDNG::Command::Clowns;

use strict;
use warnings;

use Amling::Git::G3MDNG::Command::BaseReplace;

use base ('Amling::Git::G3MDNG::Command::BaseReplace');

sub new
{
    my $class = shift;
    my $aliases = shift;
    my $idx = shift;

    my $this = $class->SUPER::new($aliases);

    $this->{'IDX'} = $idx;

    return $this;
}

sub handle3
{
    my $this = shift;
    my $loop = shift;
    my $rest = shift;

    my $chunks = $rest->[$this->{'IDX'}];

    if(@$chunks == 0)
    {
        # we leave as a conflict to avoid trying to do an empty splice
        return [['CONFLICT', [], [], []]];
    }

    return [map { ['RESOLVED', $_] } @$chunks];
}

Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['ours', '<'], 0));
Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['theirs', '>'], 2));

1;
