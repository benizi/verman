package Verman::Erlang;
use strict;
use warnings;
use base 'Verman';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  my $erlang = $self->var(erlang_root => path($self->var('root'), 'erlang'), 1);
  $self->var(erlang_versions => path($erlang, 'versions'), 1);
  $self->var(erlang_git => path($erlang, 'git'), 1);
  $self->var(erlang_upstream => 'https://github.com/erlang/otp');
  $self
}

sub setup {
  my $self = shift;
  my $git = $self->var('erlang_git');
  my $upstream = $self->var('erlang_upstream');
  my $base = basename $git;
  for ($base, $self->var('erlang_versions')) {
    mkpath $_ unless -d;
    die "Couldn't create $_ $!" unless -d;
  }
  return if -d $git;
  system { 'git' } git => clone => -o => erlang => $upstream => $git;
}

sub use {
  my ($self, $version, @rest) = @_;
  my $root = $self->var('erlang_root');
  my $versions = $self->var('erlang_versions');
  my $home = path $versions, $version;
  return 'No such Erlang' unless -d $home;
  $self->env_vars(erlang_version => $version);
  $self->no_path($root);
  $self->pre_path(path $home, 'bin');
  exec { $rest[0] } @rest if @rest;
  "using $version"
}

sub install {
  my ($self, $version, @rest) = @_;
  my %versions = $self->version_map;
  die "No such Erlang version: $version\n" unless exists $versions{$version};
  my $tag = $versions{$version};
  my $home = path $self->var('erlang_versions'), $version;
  push_dir $self->var('erlang_git');
  run qw/git clean -xdf/;
  system { 'sh' } 'sh', '-c', "git checkout -f -b $version $tag || git checkout -f $version || true";
  system <<BUILD;
git clean -xdf &&
./otp_build autoconf &&
./configure --prefix=$home &&
make &&
make install
BUILD
}

# TODO: blech
sub _version_sort {
  my $self = shift;
  map {
    $$_[0]
  } sort {
    my $ret = 0;
    my $max = (sort { $a <=> $b } $#$a, $#$b)[0];
    for my $i (1..$max) {
      $ret ||= $$a[$i] cmp $$b[$i];
    }
    $ret ||= (($$b[$max]||'') =~ /rc|release_candidate/ <=> ($$a[$max]||'') =~ /rc|release_candidate/);
    $ret ||= @$a <=> @$b;
    $ret
  } map {
    my $v = $_;
    $v =~ s/^r//i;
    my @parts = split /([\d-]+)/, $v, -1;
    [$_, @parts]
  } @_;
}

sub available {
  my $self = shift;
  $self->_version_sort(keys %{{$self->version_map}})
}

sub installed {
  my $self = shift;
  $self->_version_sort($self->SUPER::installed)
}

sub version_map {
  my ($self) = @_;
  my $git = $self->var('erlang_git');
  push_dir $git;
  my @tags = run qw/git tag/;
  my %ret = (map {
    my $tag = $_;
    (my $label = $tag) =~ s/^OTP[-_]//;
    $label =~ /^r?\d+/i ? (lc($label), $tag) : ()
  } @tags);
  pop_dir;
  %ret;
}

1;
__END__

Installation:

tag=OTP_R15B01
v=tag -> split on [_-] -> last -> lc
git checkout -b $v $tag
git clean -xdf &&
./otp_build autoconf &&
./configure --prefix=/opt/erlang/versions/$v &&
make -j$(( $(cpus) + 1 )) &&
make install


... awesome (not!) OTP_R17 === OTP-17.0
