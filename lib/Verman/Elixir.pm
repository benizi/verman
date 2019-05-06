package Verman::Elixir;
use strict;
use warnings;
use base qw/Verman::Nix Verman::SelfContained Verman::Compiled/;
use Verman::Util;
use JSON qw/decode_json/;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://github.com/elixir-lang/elixir');
  $self
}

sub _non_nix_available {
  version_sort grep /^v/, shift->SUPER::_tags
}

sub _nix_stub_dirs {
  my ($self, $v) = @_;
  my ($root, $versions) = map $self->var($self->$_), qw/_rootvar _versvar/;
  map path(@$_, $v), [$versions], [$root, 'mix'];
}

sub _make_install {
  my ($self, $prefix) = @_;
  <<BUILD;
make clean
make compile
make PREFIX=$prefix install
BUILD
}

sub after_path {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  my $version = $self->var($self->_vervar);
  $self->env_vars(MIX_HOME => path $root, 'versions', $version, 'mix')
}

sub _nix_version_prefix { 'v' }

sub _nix_finders { (qw/_nix_otp_nested/, shift->SUPER::_nix_finders(@_)) }

sub _nix_otp_nested {
  my $self = shift;
  my $dir = __FILE__;
  $dir = dirname($dir) for 1..3;
  my $nix_script = File::Spec->catfile($dir, "nix", "elixir-versions.nix");
  my $json = readpipe "nix-instantiate --json --strict --eval \Q$nix_script\E";
  my @ret = @{decode_json($json)};
  @ret = grep $$_{version} eq $_[0], @ret if @_;
  $self->_dbg_packages(_nix_otp_nested => @ret)
}

1;
