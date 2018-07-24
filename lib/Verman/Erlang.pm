package Verman::Erlang;
use strict;
use warnings;
use base 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://github.com/erlang/otp');
  $self
}

sub _make_install {
  my ($self, $prefix) = @_;
  my $flags = $self->_arch_openssl;
  <<BUILD;
set -e
./otp_build autoconf
./configure --prefix=$prefix$flags
make
make install
BUILD
}

sub _arch_openssl {
  my %flags = (
    '--with-ssl' => [qw(/usr/lib/openssl-1.0 libssl.so)],
    '--with-ssl-incl' => [qw(/usr/include/openssl-1.0 openssl/aes.h)],
  );
  my @flags = ('');
  while (my ($flag, $v) = each %flags) {
    my ($dir, $file) = @$v;
    next unless -e "$dir/$file";
    push @flags, "$flag=$dir";
  }
  "@flags"
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
  $self->_version_sort($self->_tags)
}

sub installed {
  my $self = shift;
  $self->_version_sort($self->SUPER::installed)
}

sub version_map {
  my ($self) = @_;
  my $root = $self->var($self->_rootvar);
  push_dir path $root, 'git';
  my @tags = run qw/git tag/;
  my %ret = (map {
    my $tag = $_;
    (my $label = $tag) =~ s/^OTP[-_]//;
    $label =~ /^r?\d+/i ? (lc($label), $tag) : ()
  } @tags);
  pop_dir;
  %ret;
}

sub _version_tag {
  my ($self, $version) = @_;
  my $tag = $version;
  /^OTP[-_]/i || s/^(?=\d)/OTP-/ || s/^(?=r)/OTP_/ for $tag;
  uc $tag;
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
