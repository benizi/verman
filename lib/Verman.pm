package Verman;
use strict;
use warnings;
use base 'Exporter';
use FindBin '$Bin';
use File::Basename;
use File::Find;
use Config;
use Verman::Util;
our $_abstract;

sub new {
  my $self = bless {
    seen => {},
    vars => [],
    eval => [],
  }, shift;
  my $root = $self->var(root => dirname($Bin), 1);
  $self->var(hidden => ($root eq $ENV{HOME}) ? 1 : 0, 1);
  $self->var(bin => $Bin, 1);
  $self->setup_lang_root;
  $self
}

sub eval {
  my ($self, $var, $val, $export) = @_;
  $export = $var =~ /^[A-Z]/ unless defined $export;
  push @{$$self{eval}}, [$var, $val, $export];
}

sub var_eval {
  my ($self, @rest) = @_;
  $self->var(@rest);
  $self->eval(@rest)
}

sub evalout {
  my $self = shift;
  my @eval = @{$$self{eval}};
  my %seen;
  @eval = reverse grep !$seen{$$_[0]}++, reverse @eval;
  #warn join('', ($$_[-1] ? 'export ' : ''), join('=', @$_[0,1]), "\n") for @eval;
  print $$_[-1] ? 'export ' : '', join('=', @$_[0,1]), "\n" for @eval;
}

sub var_name {
  my ($self, $var) = @_;
  join '_', map uc, split('::', __PACKAGE__), $var;
}

sub var {
  my ($self, $name, $val, $or) = @_;
  my $var = $self->var_name($name);
  push @{$$self{vars}}, $var unless $$self{seen}{$var}++;
  if (defined($val) and (!$or or !exists $ENV{$var})) {
    #warn "SETTING ENV{$var} = $val\n";
    $ENV{$var} = $val;
  }
  $ENV{$var}
}

sub lang {
  lc((split '::', ref shift)[-1])
}

sub lang_root {
  my $self = shift;
  $self->var($self->lang.'_root')
}

sub installed {
  my $self = shift;
  my ($lang_versions) =
    grep -d,
    $self->var($self->lang.'_versions'),
    join('/', $self->lang_root, 'versions');
  $lang_versions ? (ls $lang_versions) : ()
}

sub setup_lang_root {
  my $self = shift;
  my $class = ref $self;
  return if __PACKAGE__ eq $class;
  my $lang = $self->lang;
  $self->var("${lang}_root", path($self->var('root'), $lang), 1);
}

sub env_vars {
  my ($self, %env) = @_;
  while (my ($k, $v) = each %env) {
    $ENV{$k} = $v;
    $self->eval($k, $v);
  }
}

sub split_pathlike {
  my ($self, $val) = @_;
  $val ||= '';
  {
    local %ENV = (PATH => $val);
    File::Spec->path
  }
}

sub join_pathlike {
  my ($self, @path) = @_;
  join $Config{path_sep}, @path
}

sub no_path {
  my ($self, @rest) = @_;
  $self->no_pathlike(PATH => @rest)
}

sub pre_path {
  my ($self, @rest) = @_;
  $self->pre_pathlike(PATH => @rest)
}

sub no_pathlike {
  my ($self, $name, $reject, $prefix) = @_;

  my @path;
  for my $dir ($self->split_pathlike($self->var($name) || $ENV{$name})) {
    my @split = File::Spec->splitdir($dir);
    #warn "$name $dir ? $reject\n";
    next if grep File::Spec->catdir(@split[0..$_]) eq $reject, 1..$#split;
    #warn "$name $dir +\n";
    push @path, $dir;
  }
  $self->var_eval($name, $self->join_pathlike(@path))
}

sub pre_pathlike {
  my ($self, $name, $path) = @_;
  ($name, $path) = ('PATH', $name) unless $path;
  #warn sprintf("%*s ", length($path), ' ')."$ENV{$name}\n";
  $self->var_eval($name, $self->join_pathlike($path, $self->split_pathlike($self->var($name) || $ENV{$name})))
  #; warn "$ENV{$name}\n";
}

sub print_env {
  my $self = shift;
  for my $var (@{$$self{vars}}) {
    print "$var=$ENV{$var}\n";
  }
}

sub _verman_dir {
  my $path = $INC{__PACKAGE__.'.pm'};
  $path =~ s{\.pm$}{};
  File::Spec->catdir(dirname($path), @_)
}

sub load_class_for {
  my ($self, $arg) = @_;
  my @files = map basename($_, '.pm'), ls _verman_dir 'Verman';
  my ($mod) = grep { lc eq lc $arg } @files;
  die "Couldn't find Verman:: module for $arg\n" unless $mod;
  my $class = 'Verman::'.$mod;
  eval "require $class; 1" or die "$@";
  $class
}

sub runner_default {
  my ($self, $args) = @_;

  my $class = 'Verman';

  my $verman_arg0 = $$args[0] =~ /^verm(an)?$/;
  my ($runner, $default_cmd);

  if ($verman_arg0) {
    shift @$args;
    my $class = $self->load_class_for(shift @$args);
    return $class->new, 'current' if $class;
  }
  ($self, 'usage')
}

sub runner_cmd_args {
  my ($self, $args) = @_;
  return 'usage' unless @$args;

  $_ = basename $_ for $$args[0];

  my ($runner, $default_cmd) = $self->runner_default($args);

  @$args = ($default_cmd) unless @$args;

  ($runner, @$args)
}

sub _load_langs {
  my $self = shift;
  my $base = dirname $INC{'Verman.pm'};
  my @mods;

  find sub {
    return unless -f;
    (my $mod = substr $File::Find::name, 1 + length $base) =~ s{\.pm$}{};
    $mod =~ s{/}{::}g;
    eval "require $mod; 1" and push @mods, $mod;
  }, $base;

  for my $mod (@mods) {
    my $sym = \%::;
    $sym = $$sym{$_.'::'} for split /::/, $mod;
    next if exists $$sym{_abstract};
    my $lang = $mod;
    $lang =~ s{^.+::}{};
    $$self{_langs}{lc $lang} = {
      lang => $lang,
      module => $mod,
    };
  }
}

sub langs {
  my $self = shift;
  $self->_load_langs;
  sort keys %{$$self{_langs}}
}

sub cmd {
  my $self = shift;
  my ($runner, $cmd, @args) = $self->runner_cmd_args(\@_);

  unless ($runner->can($cmd)) {
    my $usage = $runner->usage;
    die "No command $cmd on ".ref($runner)."\n$usage\n";
  }

  my @ret = grep defined, $runner->$cmd(@args);

  if ($ENV{VERMAN_EVAL}) {
    $runner->evalout;
  } else {
    print "$_\n" for @ret;
  }
}

sub usage {
  my $self = shift;
  "Apparently no one wrote a usage message for ".ref($self)
}

1;
