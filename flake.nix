{
  description = "flakification of ksysguard6";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem ["x86_64-linux" "i686-linux"] (system:
      let pkgs = nixpkgs.legacyPackages.${system};

          stdenv = pkgs.stdenv;

          libksysguard = pkgs.kdePackages.libksysguard.overrideAttrs (old: {
            patches = (old.patches or []) ++ [./0001-Export-header-still-used-by-ksysguard.patch];
          });

      in {
        packages = {
          ksysguard6 = pkgs.stdenv.mkDerivation {
            pname = "ksysguard";
            version = "6.0.1";

            src = ./.;

            buildInputs =
              [
                pkgs.qt6.qtbase

                libksysguard

                pkgs.lm_sensors

                pkgs.libpcap
                pkgs.libnl
              ];

            # takes care of placing the .desktop under $out/share/applications/hello.desktop
            nativeBuildInputs =
              [
                pkgs.extra-cmake-modules
                pkgs.kdePackages.kdoctools
                pkgs.qt6.wrapQtAppsHook
              ] ++
              (pkgs.lib.optionals stdenv.isLinux [ pkgs.copyDesktopItems ]);

            cmakeFlags = [
              "BUILD_TESTING=OFF"
              "WITH_SYSTEMMONITOR=OFF"
              # Debug build
              # "CMAKE_VERBOSE_MAKEFILE=ON"
              # "VERBOSE=ON"
            ];

            # How general mkDerivation looks like
            # buildPhase = ''
            #   ./configure
            #   make
            # '';
            #
            # installPhase = ''
            #   mkdir -p $out/bin
            #   cp hello $out/bin
            # '';
            #
            # postInstall =
            #   with pkgs;
            #   lib.optionalString stdenv.isLinux ''
            #     # install icon
            #     mkdir -p "$out/share/icons/hicolor/scalable/apps"
            #     install -Dm644 icons/logo.svg $out/share/icons/hicolor/scalable/apps/org.reciperium.hello.svg
            #   '';
          };
        };
      }
    );
}

# mkDerivation {
#   pname = "plasma-systemmonitor";
#   nativeBuildInputs = [
#     extra-cmake-modules
#     kdoctools
#   ];
#   buildInputs = [
#     qtquickcontrols2
#     kconfig
#     kcoreaddons
#     ki18n
#     kitemmodels
#     kitemviews
#     knewstuff
#     kiconthemes
#     libksysguard
#     kquickcharts
#     ksystemstats
#     qqc2-desktop-style
#   ];
# }

