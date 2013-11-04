#! /usr/bin/env perl

use strict;
use Statistics::Descriptive;
use Statistics::TTest;
use Unix::Getrusage;
use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use File::Slurp;
use Getopt::Long qw(:config gnu_getopt);

my $times = 10;
my $file;
my $other; # path to other sample set
my $rtrim = 10;

GetOptions("times|t=n" => \$times,
           "file|f=s" => \$file,
           "compare|c=s" => \$other,
           "rtrim=n" =>\$rtrim
           #"help" => sub { showHelp() }
    )
    or die("syntax: $0 ...\n");

my $stats = {};

if (scalar @ARGV > 0) {

    for (my $n = 0; $n < $times; $n++) {
        print STDERR "run $n...\n";
        pipe RH, WH;
        my $pid = fork();
        if ($pid == 0) {
            close RH;
            my $t1 = gettimeofday();
            system("taskset", "-c", "6", @ARGV);
            my $t2 = gettimeofday();
            my $usage = getrusage_children;
            $usage->{walltime} = $t2 - $t1;
            print WH Dumper($usage);
            exit 0;
        }
        close WH;
        local $/;
        my $VAR1;
        eval <RH>;
        my $usage = $VAR1;
        for my $k (keys %$usage) {
            push @{$stats->{$k}}, $usage->{$k};
        }
        waitpid $pid, 0 or die;
    }

    write_file($file, Dumper($stats)) if defined $file;

} elsif (defined $file && -f $file) {
    my $VAR1;
    eval read_file($file);
    $stats = $VAR1;
} else {
    die "$0: please specify a command or an existing stats file (-f)\n";
}

my $prev;
if (defined $other) {
    my $VAR1;
    eval read_file($other);
    $prev = $VAR1;
}

print STDERR "note: discarding $rtrim% highest outliers\n";

sub trimData {
    my @data = sort { $a <=> $b} @_;
    return @data[0..(scalar @data) * (1 - ($rtrim / 100.0)) - 1];
}

sub show {
    my ($s) = @_;
    my @data = trimData @{$stats->{$s}};

    return if scalar(grep { $_ != 0 } @data) == 0;
    my $x = Statistics::Descriptive::Full->new;
    $x->add_data(@data);

    my $names =
        { "ru_utime" => "user CPU time"
        , "ru_stime" => "system CPU time"
        , "ru_maxrss" => "maximum RSS"
        , "ru_minflt" => "soft page faults"
        , "walltime" => "elapsed time"
        };
    my $h = $names->{$s} // $s;
    $h .= ":";
    $h .= " " while length $h < 20;

    my $res;
    if ($prev) {
        my $ttest = new Statistics::TTest;
        $ttest->set_significance(99.5);
        $ttest->load_data([@data], [trimData@{$prev->{$s}}]);
        $res .= "  [";
        $res .= sprintf "%s%s, p=%.5f", $ttest->null_hypothesis, ($ttest->{equal_variance} ? "" : "?"), $ttest->t_prob;
        $res .= sprintf ", Δ=%.5f±%.5f", $ttest->mean_difference, $ttest->delta;
        $res .= "]";
    }

    my $f = "%11.4f";
    printf "${h}median = $f  mean = $f  stddev = $f  min = $f  max = $f$res\n",
        $x->median, $x->mean, $x->standard_deviation, $x->min, $x->max;

}

for my $k (sort keys %$stats) {
    next unless grep { $_ eq $k } ("walltime", "ru_stime", "ru_utime", "ru_maxrss", "ru_minflt");
    show $k;
}
