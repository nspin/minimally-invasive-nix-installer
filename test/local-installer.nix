let
  pkgs = import ../nixpkgs {};
  release = import ../release.nix {};

  tarballName = "x.tar.gz";
  tarballUrl = "http://localhost:8000/${tarballName}";

  scriptName = "install.sh";
  script = release.mkScript {
    inherit tarballUrl;
  };

in {

  testBundle = pkgs.runCommand "test_bundle" {} ''
    mkdir $out
    cp ${release.tarball} $out/${tarballName}
    cp ${script} $out/${scriptName}
  '';

}
