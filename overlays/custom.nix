self: super: {
  warp-terminal = super.callPackage (
    { stdenv, fetchurl, dpkg, makeWrapper, openssl, alsa-lib, libGL, libX11, libxkbcommon, vulkan-loader, ... }:
    stdenv.mkDerivation rec {
      name = "warp-terminal";
      version = "0.2024.02.20.08.01.stable.02";
      src = fetchurl {
        url = "https://releases.warp.dev/stable/v0.2024.02.20.08.01.stable_02/warp-terminal_${version}_amd64.deb";
        sha256 = "sha256-F0CfKTtgHOoeJienFAoqdYKV/0ZTsC1GhzOeQFl3oDk=";
      };
      nativeBuildInputs = [ dpkg makeWrapper ];
      buildInputs = [ openssl alsa-lib libGL libX11 libxkbcommon vulkan-loader ];
      unpackPhase = "dpkg-deb -x $src .";
      installPhase = ''
        mkdir -p $out
        cp -r opt $out/
        cp -r usr/share $out/share
        makeWrapper $out/opt/warpdotdev/warp-terminal/warp $out/bin/warp-terminal
      '';
    }
  ) {};
}
