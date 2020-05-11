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
  $self->_dbg_packages(_nix_store_dirs => @ret)
}

sub _nix_env_versions {
  my $self = shift;
  my $pkg = $self->nixpkg;
  my $search = join '-', $pkg, @_;
  my @ret;
  for (readpipe "nix-env -qasP --drv-path --out-path $search") {
    chomp;
    my ($status, $attr, $name, $drv, $out) = split;
    $attr =~ s{^nixpkgs\.}{};
    my @status = split //, $status;
    my $flags = {};
    # Nix status marker is three chars:
    for my $flag (
      'installed', # I.. - installed
      'present', # .P. - present (instantiated)
      'substitution', # ..S - substitution available (usually a binary install)
    ) {
      $$flags{$flag} = ('-' ne shift @status) ? 1 : 0;
    }
    (my $v = $name) =~ s/^\Q$pkg\E-//;
    push @ret, {
      version => $v,
      full => $out,
      drv => $drv,
      attr => $attr,
      flags => $flags,
    };
  }
  $self->_dbg_packages(_nix_env_versions => @ret)
}

sub _dbg_packages {
  my ($self, $fn, @ret) = @_;
  if (exists $ENV{verman_debug}) {
    eval { require Data::Dumper };
    warn Data::Dumper->new([\@ret],['*'.$fn])->Terse(0)->Indent(1)->Dump;
  }
  @ret
}

sub nix_versions {
  my ($self) = @_;
  my %pkgs;
  $pkgs{$$_{version}}++ for map $self->$_, $self->_nix_finders;
  map $self->to_display_version($_), keys %pkgs
}

sub available {
  my $self = shift;
  my $non_nix = $self->can('_non_nix_available') || sub { };
  $self->$non_nix(@_), version_sort($self->nix_versions)
}

sub install {
  my ($self, $v) = @_;
  my $nix_v = $self->_nix_parse($v);
  return $self->next::method($v) if $nix_v eq $v;
  my %mkdirs;
  my $nix_stubs = $self->can('_nix_stub_dirs') || sub {};
  my $post_install = $self->can('_post_build') || sub {};
  my $prefix = path $self->var($self->_versvar), $v;
  my $gcroot = path '/nix/var/nix/gcroots/per-user', $ENV{USER};
  $mkdirs{$_}++ for $prefix, $gcroot, $self->$nix_stubs($v, $prefix);
  my @mkdirs = map "mkdir -p $_", keys %mkdirs;
  my ($installable) = $self->_nix_find_installable($nix_v);
  die "Couldn't find version ($v) in Nix store or pkgs\n" unless $installable;
  my ($nix_root, $drv, $attr) = @{$installable}{qw/full drv attr/};
  my @realize;
  unless (-d $nix_root) {
    my $drv_val = $attr ? qq[\$(nix-instantiate '<nixpkgs>' -A $attr)] : $drv;
    @realize = (qq[drv="$drv_val"], 'nix-store -r "$drv"');
  }
  my @ln = map {
    my ($target, $source) = @$_;
    "ln -sf --target-directory=$target $source";
  } $self->_nix_symlinks($v, $prefix, $nix_root), [$gcroot, $nix_root];
  my @post = $self->$post_install($v);
  'set -e', @realize, @mkdirs, @ln, @post
}

sub _nix_symlinks {
  my $self = shift;
  my ($prefix, $nix_root) = @_;
  [$prefix, "$nix_root/bin"]
}

sub _nix_find_installable {
  my $self = shift;
  my ($nix_v) = @_;
  my @ret;
  for my $finder ($self->_nix_finders(@_)) {
    push @ret, $self->$finder(@_);
    last if @_ and @ret;
  }
  $self->_dbg_packages(_nix_find_installable => @ret)
}

sub _nix_finders { qw(_nix_instantiated _nix_env_versions) }

sub _nix_instantiated {
  # Find the newest entry in the store (by ctime) that has a matching version.
  my $self = shift;
  my ($nix_v) = @_;
  map $$_[0],
  sort { $$b[1] <=> $$a[1] }
  map [$_, (stat $$_{full})[10]],
  grep @_ ? $$_{version} eq $nix_v : 1,
  $self->_nix_store_dirs
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
  $v =~ /^\Q$pre\E(.+)\Q$suf\E$/ ? $1 : $v
}

1;
