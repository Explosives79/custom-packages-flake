{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, glib
, gtk3
, webkitgtk_4_1
, wrapGAppsHook3
, wayland
, libxkbcommon
, libepoxy
, libGL
, dbus
, pango
, cairo
, atk
, gdk-pixbuf
, zlib
, vulkan-loader
, egl-wayland
, curl
, openssl
, libappindicator-gtk3
}:

stdenv.mkDerivation rec {
  pname = "tachidesk-sorayomi";
  version = "0.6.3";

  src = fetchurl {
    url = "https://github.com/Suwayomi/Tachidesk-Sorayomi/releases/download/${version}/tachidesk-sorayomi_${version}-1_amd64.deb";
    hash = "sha256-ilbSryDod+lXS4VIN365EbduGMo/LdFSXh8fvlrm1P8=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    glib
    gtk3
    webkitgtk_4_1
    wayland
    libxkbcommon
    libepoxy
    libGL
    dbus
    pango
    cairo
    atk
    gdk-pixbuf
    zlib
    curl
    openssl
    libappindicator-gtk3
  ];

  runtimeDependencies = [
    vulkan-loader
    egl-wayland
  ];

  unpackPhase = ''
    dpkg -x $src .
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r opt $out/opt
    cp -r usr/share $out/share

    # The executable is in /opt/tachidesk-sorayomi/tachidesk_sorayomi
    # and /usr/bin/tachidesk-sorayomi is a symlink to it in the deb.
    mkdir -p $out/bin
    ln -s $out/opt/tachidesk-sorayomi/tachidesk_sorayomi $out/bin/tachidesk-sorayomi

    # Fix desktop file
    substituteInPlace $out/share/applications/tachidesk-sorayomi.desktop \
      --replace "Exec=/opt/tachidesk-sorayomi/tachidesk_sorayomi" "Exec=tachidesk-sorayomi" \
      --replace "Icon=tachidesk-sorayomi" "Icon=$out/share/pixmaps/tachidesk-sorayomi.png"

    runHook postInstall
  '';

  meta = with lib; {
    description = "A free and open source manga reader for the desktop.";
    homepage = "https://github.com/Suwayomi/Tachidesk-Sorayomi";
    license = licenses.mpl20;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
  };
}
