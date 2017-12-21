package Verman::Nix;
use mro;
use strict;
use warnings;

our $_abstract;

sub nixversion {
  my $self = shift;
  my $exe = $self->exe;
  my @files = grep -l, map File::Spec->catfile($_, $exe), File::Spec->path;
  for (@files) {
    $_ = readlink;
    s{^/nix/store/\w+-$exe-}{};
    s{\/.*$}{};
  }
  map $self->to_display_version($_), @files
}

sub installed {
  my $self = shift;
  $self->nixversion, $self->next::method(@_)
}

sub nixpkg { shift->_nixpkg }
sub exe { shift->_nixpkg }

sub to_display_version {
  my ($self, $v) = @_;
  $self->_nix_display($v)
}

sub _nixpkg {
  my $pkg = ref shift;
  $pkg =~ s/^.*:://;
  lc $pkg
}

sub _nix_version_prefix { '' }
sub _nix_version_suffix { '-nix' }
sub _nix_display {
  my ($self, $v) = @_;
  join '', $self->_nix_version_prefix, $_, $self->_nix_version_suffix
}

1;
