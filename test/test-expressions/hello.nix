{ lib
, stdenv
, fetchurl
, testVersion
, hello
}:

stdenv.mkDerivation rec {
  pname = "hello";
  version = "2.10";

  src = fetchurl {
    url = "mirror://gnu/hello/${pname}-${version}.tar.gz";
    sha256 = "0ssi1wpaf7plaswqqjwigppsg5fyh99vdlb9kzl7c9lng89ndq1i";
  };

  doCheck = true;

  featureTest = builtins.fetchGit {
    url = "https://github.com/nspin/seL4.git";
    rev = "13d1a9963b8a1e135c0dad7b2020851797e8e34f";
    submodules = true;
  };
}
