package Amling::Git::G3MDNG::Command::Nav;

use strict;
use warnings;

use Amling::Git::G3MDNG::Command::Base;

use base ('Amling::Git::G3MDNG::Command::Base');

sub new
{
    my $class = shift;
    my $aliases = shift;
    my $dir = shift;

    my $this = $class->SUPER::new($aliases);

    $this->{'DIR'} = $dir;

    bless $this, $class;

    return $this;
}

sub args_regex
{
    return qr/(?:\s(\d+))?/;
}

sub handle2
{
    my $this = shift;
    my $loop = shift;
    my $state = shift;
    my $ct = shift || 1;

    $state->move_delta($this->{'DIR'} * $ct);

    return 1;
}

Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['Next', 'N'], 1));
Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['Previous', 'Prev', 'P'], -1));

1;
