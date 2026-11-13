{ appimageTools, fetchurl }:

let
  pname = "openscreen";
  version = "1.5.0";
  src = fetchurl {
    url = "https://github.com/siddharthvaddem/openscreen/releases/download/v1.5.0/Openscreen-Linux-1.5.0.AppImage";
    sha256 = "1kah3q8d30rh80b5acnad2asri3a3v1rdg6r8f298sc1plv4cndy";
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;
  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/openscreen.desktop \
      $out/share/applications/openscreen.desktop
    substituteInPlace $out/share/applications/openscreen.desktop \
      --replace 'Exec=AppRun --no-sandbox %U' 'Exec=openscreen %U'
    install -m 444 -D ${appimageContents}/openscreen.png \
      $out/share/icons/hicolor/512x512/apps/openscreen.png
  '';
}
