package Amling::Git::G3MDNG::Command::StateMethods;

use strict;
use warnings;

use Amling::Git::G3MDNG::Command::Base;

use base ('Amling::Git::G3MDNG::Command::Base');

sub new
{
    my $class = shift;
    my $aliases = shift;
    my $method = shift;

    my $this = $class->SUPER::new($aliases);

    $this->{'METHOD'} = $method;

    return $this;
}

sub handle2
{
    my $this = shift;
    my $loop = shift;
    my $state = shift;

    my $method = $this->{'METHOD'};
    return $state->$method();
}

Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['undo', 'u'], 'undo'));
Amling::Git::G3MDNG::Command::add_command(__PACKAGE__->new(['redo', 'r'], 'redo'));

1;
