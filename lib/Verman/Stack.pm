package Verman::Stack;
use strict;
use warnings;
use base 'Verman::SelfContained';
use Verman::Util qw/path/;

sub install {
  my ($self, $version) = @_;
  (my $vnum = $version) =~ s/^v//;
  my $download = "https://github.com/commercialhaskell/stack/releases/download";
  my $file = "stack-$vnum-linux-x86_64.tar.gz";
  my $url = "$download/v$vnum/$file";
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $prefix = path $versions, $version;
  my $stack_global_root = path $root, 'root', $version;
  my $cache = path $root, 'downloads';
  <<BUILD;
mkdir -p $cache $prefix $stack_global_root &&
printf 'Downloading %s...\\n' "$url" &&
(test -f $cache/$file || curl -L -o $cache/$file $url) &&
printf 'Done\\n' &&
tar --strip-components=1 -xzf $cache/$file -C $prefix &&
mkdir -p $prefix/bin &&
mv $prefix/stack $prefix/bin/ &&
printf 'system-ghc: false\n' > $stack_global_root/config.yaml
BUILD
}

sub available {
  qw{v0.1.8.0 v1.0.2}
}

sub after_path {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  my $version = $self->var($self->_vervar);
  my $stack_global_root = path $root, 'root', $version;
  $self->env_vars(STACK_ROOT => $stack_global_root)
}

1;
