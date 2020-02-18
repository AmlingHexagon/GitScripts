package Amling::Git::GRD::Command::Merge;

use strict;
use warnings;

use Amling::Git::GRD::Command::Load;
use Amling::Git::GRD::Command::Simple;
use Amling::Git::GRD::Command;
use Amling::Git::GRD::Exec::Context;
use Amling::Git::GRD::Utils;
use Amling::Git::Utils;

use base 'Amling::Git::GRD::Command::Simple';

sub name
{
    return "merge";
}

sub min_args
{
    return 2;
}

sub max_args
{
    return undef;
}

sub execute_simple
{
    my $self = shift;
    my $ctx = shift;
    my $parent0 = Amling::Git::GRD::Command::Load::convert_arg("Merge", $ctx, shift);
    my @parents1 = map { Amling::Git::GRD::Command::Load::convert_arg("Merge", $ctx, $_) } @_;

    merge_common($ctx, $parent0, \@parents1, undef);
}

sub merge_common
{
    my $ctx = shift;
    my $parent0 = shift;
    my @parents1 = @{+shift};
    my $msg = shift;

    my $env =
    {
        'PARENT0' => $parent0,
        'PARENTS1' => join(' ', @parents1),
    };

    $ctx->materialize_head($parent0);

    my @msg_args;
    if(defined($msg))
    {
        @msg_args = ("-m", $msg);
    }

    if(!Amling::Git::Utils::run_system("git", "merge", "--no-edit", "--commit", "--no-ff", @msg_args, @parents1))
    {
        print "git merge of " . join(", ", @parents1) . " into $parent0 blew chunks, please clean it up (get correct version into index)...\n";
        Amling::Git::GRD::Utils::run_shell(1, 1, 0, $env);
        print "Continuing...\n";

        if(Amling::Git::Utils::is_clean())
        {
            print "Shell left clean, assuming skip...\n";
            $ctx->uptake_head();
            return;
        }

        if(defined($msg))
        {
            # allow edit since we would normally
            Amling::Git::Utils::run_system("git", "commit", "-m", $msg, "-e") || die "Cannot commit?";

            # no further amendment required
            $msg = undef;
        }
        else
        {
            Amling::Git::Utils::run_system("git", "commit") || die "Cannot commit?";
        }
    }
    $ctx->uptake_head();

    # similar to pick, only run post-merge in cases where "we" actually
    # performed a merge
    $ctx->run_hooks('post-merge', $env);
}

Amling::Git::GRD::Command::add_command(sub { return __PACKAGE__->handler(@_) });
Amling::Git::GRD::Exec::Context::add_event('post-merge');

1;
