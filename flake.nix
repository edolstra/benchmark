{
  inputs = {
    flakeUtils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { flakeUtils, nixpkgs, ... }:
    flakeUtils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          defaultPackage = pkgs.stdenv.mkDerivation {
            pname = "benchmark";
            version = "1.0.0";

            buildInputs = with pkgs.perlPackages; [
              pkgs.makeWrapper
              perl
              StatisticsDescriptive
              StatisticsTTest
              UnixGetrusage
              FileSlurp
            ];

            unpackPhase = "true";
            buildPhase = "true";

            installPhase = ''
              mkdir -p $out/bin
              cp ${./benchmark.pl} $out/bin/benchmark
              wrapProgram $out/bin/benchmark --set PERL5LIB $PERL5LIB
            '';

            meta = {
              maintainers = [ nixpkgs.lib.maintainers.eelco ];
              description = "Run a command multiple times and print CPU/memory statistics";
            };
          };

          defaultApp = {
            type = "app";
            program = "${defaultPackage}/bin/benchmark";
          };
        });
}
