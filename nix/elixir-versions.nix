# Find all OTP-nested Elixir versions, e.g.:
#   'nixpkgs.beam.packages.erlangR21.elixir_1_8'
with builtins ;
let
  nixpkgs = (import <nixpkgs> {}) ;
  beampkgs = nixpkgs.beam.packages ;
  orElse = expr: default: let ret = (tryEval expr) ;
  in if ret.success then ret.value else default ;
  pkg = erl: a: beampkgs.${erl}.${a} ;
  hasPrefix = need: hay: need == (substring 0 (stringLength need) hay) ;
  startsWith = need: hay: [] == (match (need + ".*") hay) ;
  erls = (filter (hasPrefix "erlangR") (attrNames beampkgs)) ;
  elixirs = erl: (filter (startsWith "elixir_[0-9]+_")
    (filter (hasPrefix "elixir_")
    (attrNames (getAttr erl beampkgs)))) ;
  ver = erl: a: (orElse (getAttr "version" (pkg erl a)) null) ;
  versions = erl: elixir: {
    attr = (concatStringsSep "." ["beam" "packages" erl elixir]) ;
    full = (orElse beampkgs.${erl}.${elixir} null) ;
    otp = (elemAt (match "erlang(R[0-9]+)" erl) 0) ;
    erlang = (ver erl "erlang") ;
    elixir = (ver erl elixir) ;
  } ;
  valid = x: !(any isNull (attrValues x)) ;
  expand = info @ { elixir, otp, full, ... }: info // {
    version = "${elixir}-${otp}" ;
    drv = full.drvPath ;
    full = full.outPath ;
  } ;
  flatMap = f: l: (foldl' (acc: i: acc ++ (f i)) [] l) ;
  allVersions = (flatMap (erl: (map (versions erl) (elixirs erl))) erls) ;
in (map expand (filter valid allVersions))
