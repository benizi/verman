package Verman::Nix;
use mro;
use strict;
use warnings;
use Verman::Util;

our $_abstract;

sub _nix_store_dirs {
  my $self = shift;
  my $store = '/nix/store';
  my $pkg = $self->nixpkg;
  my $pfx = qr{^(\w{32})-\Q$pkg\E-};
  my @ret;
  for (ls $store) {
    my $base = $_;
    next unless s/$pfx//;
    next if /-[a-z]+$/;
    my $v = $_;
    my $full = "$store/$base";
    next unless -d $full;
    push @ret, {version => $v, full => $full};
  }
  @ret
}

sub nix_versions {
  my ($self) = @_;
  my %pkgs;
  $pkgs{$_}++ for map $$_{version}, $self->_nix_store_dirs;
  map $self->to_display_version($_), keys %pkgs
}

sub available {
  my $self = shift;
  my $non_nix = $self->can('_non_nix_available') || sub { };
  $self->nix_versions, $self->$non_nix(@_)
}

sub install {
  my ($self, $v) = @_;
  my $nix_v = $self->_nix_parse($v);
  return $self->next::method($v) if $nix_v eq $v;
  my %mkdirs;
  my $nix_stubs = $self->can('_nix_stub_dirs') || sub {};
  my $post_install = $self->can('_post_build') || sub {};
  my $prefix = path $self->var($self->_versvar), $v;
  $mkdirs{$_}++ for $prefix, $self->$nix_stubs($v);
  my @mkdirs = keys %mkdirs;
  # Find the newest entry in the store (by ctime) that has a matching version.
  my ($nix_root) =
    map $$_[0],
    sort { $$b[1] <=> $$a[1] }
    map [$_, (stat)[10]],
    map $$_{full},
    grep $$_{version} eq $nix_v,
    $self->_nix_store_dirs;
  die "Couldn't find version ($v) in /nix/store\n" unless $nix_root;
  my $nix_bin = path $nix_root, 'bin';
  <<INSTALL, $self->$post_install($v);
set -e
mkdir -p @mkdirs
ln -sf --target-directory=$prefix $nix_bin
INSTALL
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
sub _nix_parse {
  my ($self, $v) = @_;
  my ($pre, $suf) = ($self->_nix_version_prefix, $self->_nix_version_suffix);
  $v =~ s/^\Q$pre\E//;
  $v =~ s/\Q$suf\E$//;
  $v
}

1;
