{
  lib,
  fetchurl,
  appimageTools,
  ffmpeg,
  makeWrapper,
}:
let
  pname = "stremio-enhanced";
  version = "1.1.5";
  src = fetchurl {
    url = "https://github.com/REVENGE977/stremio-enhanced/releases/download/v${version}/Stremio.Enhanced-${version}.AppImage";
    hash = "sha256-ATy2ekUWGI3s+CtQemQ2hXOe7etk56hXHWarWC607GA=";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
  serverJs = fetchurl {
    url = "https://dl.strem.io/server/v4.20.17/desktop/server.js";
    hash = "sha256-Vno5e7EbeIVxvxdQ/QXdeJJ/l77Ayd3qptnMHszuOSI=";
  };
in
appimageTools.wrapType2 {
  inherit pname version src;
  nativeBuildInputs = [ makeWrapper ];
  extraPkgs =
    pkgs: with pkgs; [
      ffmpeg
    ];
  extraInstallCommands = ''
    # Desktop entry
    if [ -f ${appimageContents}/stremio-enhanced.desktop ]; then
      install -m 444 -D ${appimageContents}/stremio-enhanced.desktop \
        $out/share/applications/${pname}.desktop
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=${pname}' \
        --replace-fail 'Icon=stremio-enhanced' 'Icon=${pname}'
    fi

    # Icon
    if [ -f ${appimageContents}/stremio-enhanced.png ]; then
      install -m 444 -D ${appimageContents}/stremio-enhanced.png \
        $out/share/icons/hicolor/512x512/apps/${pname}.png
    fi

    # Install server.js into the store (like the official package does)
    install -m 444 -D ${serverJs} \
      $out/share/${pname}/streamingserver/server.js

    # On first run, copy server.js to the user config dir that the app expects.
    # Uses the same pattern as the official stremio package's postInstall,
    # but adapted for an AppImage that can't be patched at source level.
    wrapProgram $out/bin/${pname} \
      --run 'mkdir -p "$HOME/.config/stremio-enhanced/streamingserver"' \
      --run 'test -f "$HOME/.config/stremio-enhanced/streamingserver/server.js" || cp '"${serverJs}"' "$HOME/.config/stremio-enhanced/streamingserver/server.js"'
  '';
  meta = with lib; {
    description = "Stremio Enhanced - Stremio with enhanced features";
    homepage = "https://github.com/REVENGE977/stremio-enhanced";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "stremio-enhanced";
  };
}
