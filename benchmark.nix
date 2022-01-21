with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "benchmark-1";

  buildInputs =
    with perlPackages;
    [ makeWrapper perl StatisticsDescriptive StatisticsTTest
      UnixGetrusage FileSlurp
    ];

  unpackPhase = "true";
  buildPhase = "true";

  installPhase =
    ''
      mkdir -p $out/bin
      cp ${./benchmark.pl} $out/bin/benchmark
      wrapProgram $out/bin/benchmark --set PERL5LIB $PERL5LIB
    '';

  meta = {
    maintainers = [ lib.maintainers.eelco ];
    description = "Run a command multiple times and print CPU/memory statistics";
  };
}