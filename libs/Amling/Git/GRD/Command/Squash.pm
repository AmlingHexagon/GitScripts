package Amling::Git::GRD::Command::Squash;

use strict;
use warnings;

use Amling::Git::GRD::Command::Pick;
use Amling::Git::GRD::Command::Simple;
use Amling::Git::GRD::Command::Splatter;
use Amling::Git::GRD::Command;
use Amling::Git::GRD::Utils;
use Amling::Git::Utils;

use base 'Amling::Git::GRD::Command::Simple';

sub extended_handler
{
    my $s0 = shift;
    my $s1 = shift;

    if($s0 !~ /^squash ([^ ]+) ([^#].*)$/)
    {
        return undef;
    }
    my $commit = $1;
    my $msg = Amling::Git::GRD::Utils::unescape_msg($2);

    return [__PACKAGE__->new($commit, $msg), $s1];
}

sub name
{
    return "squash";
}

sub args
{
    return 1;
}

sub execute_simple
{
    my $self = shift;
    my $ctx = shift;
    my $commit = shift;
    my $msg = shift;

    # push HEAD^
    push @{$ctx->get('commit-stack', [])}, Amling::Git::Utils::convert_commitlike($ctx->get_head() . '^');

    # pick *
    my $pick_delegate;
    if(defined($msg))
    {
        $pick_delegate = Amling::Git::GRD::Command::Pick->new($commit, $msg);
    }
    else
    {
        $pick_delegate = Amling::Git::GRD::Command::Pick->new($commit);
    }
    $pick_delegate->execute($ctx);

    # splatter
    my $splatter_delegate = Amling::Git::GRD::Command::Splatter->new();
    $splatter_delegate->execute($ctx);
}

sub str_simple
{
    my $self = shift;
    my $commit = shift;
    my $msg = shift;

    return "squash $commit" . (defined($msg) ? " (amended message)" : "");
}

Amling::Git::GRD::Command::add_command(\&extended_handler);
Amling::Git::GRD::Command::add_command(sub { return __PACKAGE__->handler(@_) });

1;
