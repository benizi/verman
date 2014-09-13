package Verman::Util;
use strict;
use warnings;
use Verman::Util;
use File::Basename;
use File::Spec;
use File::Path 'mkpath';
use Cwd;
use base 'Exporter';
our @EXPORT = qw(
  &version_sort
  &mkpath
  &path
  &need
  &basename
  &dirname
  &ls
  &push_dir
  &pop_dir
  &run
);

sub version_sort {
  my $n = 6;
  my $nfmt = "%0${n}d";
  my $sfmt = "%${n}s";
  map $$_[0],
  sort { $$a[1] cmp $$b[1] }
  map [
    $_,
    join('', map sprintf(/\d/ ? $nfmt : $sfmt, /\d/ ? eval : $_), split /(\d+)/),
  ], @_
}

sub path { File::Spec->catfile(@_) }

sub need {
  for my $cmd (@_) {
    next if grep -e, map File::Spec->catfile($_, $cmd), File::Spec->path;
    die "The \`$cmd\` command is required\n";
  }
}

sub ls {
  my $dir = shift;
  my @files;
  if (opendir my $d, $dir) {
    @files = grep !/\A\.\.?\Z/, readdir $d;
    closedir $d;
  }
  @files;
}

{
  my @dirs = ();
  sub push_dir {
    my ($dir) = @_;
    push @dirs, getcwd;
    chdir $dir or die "Couldn't chdir to $dir: $!";
  }

  sub pop_dir {
    @dirs and chdir pop @dirs;
  }
}

sub run {
  my (@cmd) = @_;
  need $cmd[0];
  chomp(my @lines = `@cmd`);
  @lines;
}

1;
