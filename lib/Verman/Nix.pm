package Verman::Nix;
use mro;
use strict;
use warnings;

sub nixversion {
  my $self = shift;
  my $exe = $self->exe;
  my @files = grep -l, map File::Spec->catfile($_, $exe), File::Spec->path;
  for (@files) {
    $_ = readlink;
    s{^/nix/store/\w+-$exe-}{};
    s{\/.*$}{};
  }
  map $self->normalversion($_), @files
}

sub installed {
  my $self = shift;
  $self->nixversion, $self->next::method(@_)
}

sub nixpkg { shift->_nixpkg }
sub exe { shift->_nixpkg }

sub normalversion {
  my ($self, $v) = @_;
  $self->_nix_normal($v)
}

sub _nixpkg {
  my $pkg = ref shift;
  $pkg =~ s/^.*:://;
  lc $pkg
}

sub _nix_version_prefix { 'nix' }
sub _nix_version_separator { '-' }
sub _nix_normal {
  my ($self, $v) = @_;
  join $self->_nix_version_separator, $self->_nix_version_prefix, $v
}

1;
