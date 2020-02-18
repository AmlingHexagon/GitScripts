package Amling::Git::GRD::Command::TemplateMerge;

use strict;
use warnings;

use Amling::Git::GRD::Command::Load;
use Amling::Git::GRD::Command::Merge;
use Amling::Git::GRD::Command::Simple;
use Amling::Git::GRD::Command;
use Amling::Git::GRD::Exec::Context;
use Amling::Git::GRD::Utils;
use Amling::Git::Utils;

use base 'Amling::Git::GRD::Command::Simple';

sub name
{
    return "template-merge";
}

sub min_args
{
    return 3;
}

sub max_args
{
    return undef;
}

sub execute_simple
{
    my $self = shift;
    my $ctx = shift;
    my $template = Amling::Git::GRD::Command::Load::convert_arg("Merge", $ctx, shift);
    my $parent0 = Amling::Git::GRD::Command::Load::convert_arg("Merge", $ctx, shift);
    my @parents1 = map { Amling::Git::GRD::Command::Load::convert_arg("Merge", $ctx, $_) } @_;

    my $ok = 0;
    my $msg;
    {
        open(my $fh, '-|', 'git', 'log', '-1', $template, '--format=%P%n%B') || die "Cannot open log -1 $template: $!";
        my $line = <$fh> || die "Could not read log -1 $template";
        chomp $line;
        $msg = join("", <$fh>) || die "Could not read log -1 $template";
        chomp $msg;
        if($line eq join(" ", $parent0, @parents1))
        {
            $ok = 1;
        }
        close($fh) || die "Cannot close log -1 $template: $!";
    }

    if($ok)
    {
        print "Fast-forward merging $template...\n";
        $ctx->set_head($template);
        # Don't run hooks in this case?  Parallels pick, but is definitely
        # debatable...
        return;
    }

    Amling::Git::GRD::Command::Merge::merge_common($ctx, $parent0, \@parents1, $msg);
}

Amling::Git::GRD::Command::add_command(sub { return __PACKAGE__->handler(@_) });
Amling::Git::GRD::Exec::Context::add_event('post-merge');

1;
