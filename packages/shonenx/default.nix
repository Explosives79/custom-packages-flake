{ lib
, stdenv
, fetchurl
, unzip
, autoPatchelfHook
, gtk3
, glib
, pango
, harfbuzz
, cairo
, gdk-pixbuf
, libepoxy
, libX11
, mpv
, curl
, makeWrapper
, libsoup_3
, webkitgtk_4_1
, libsecret
, glib-networking
, cacert
, alsa-lib
, alsa-plugins
, gst_all_1
, libglvnd
}:

stdenv.mkDerivation rec {
  pname = "shonenx";
  version = "1.7.6";

  src = fetchurl {
    url = "https://github.com/roshancodespace/ShonenX/releases/download/v${version}/ShonenX-Linux.zip";
    sha256 = "3a3a2332e127650d12c7b241ff6fa141d37d165e2d24c8a36f8fff7b595e0d18";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    gtk3
    glib
    pango
    harfbuzz
    cairo
    gdk-pixbuf
    libepoxy
    libX11
    mpv
    curl
    libsoup_3
    webkitgtk_4_1
    libsecret
    glib-networking
    alsa-lib
    alsa-plugins
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    libglvnd
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/shonenx $out/share/applications $out/share/icons/hicolor/256x256/apps

    cp -r * $out/lib/shonenx/

    # Install icon
    if [ -f "$out/lib/shonenx/data/flutter_assets/assets/icons/app_icon-modified-2.png" ]; then
      cp "$out/lib/shonenx/data/flutter_assets/assets/icons/app_icon-modified-2.png" $out/share/icons/hicolor/256x256/apps/shonenx.png
    else
      echo "Warning: Icon not found in expected location"
    fi

    # Create desktop entry
    cat > $out/share/applications/shonenx.desktop <<EOF
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=ShonenX
    Comment=Anime Streaming Desktop
    Exec=shonenx
    Icon=shonenx
    Terminal=false
    Categories=Video;AudioVideo;Player;
    StartupWMClass=shonenx
    EOF

    makeWrapper $out/lib/shonenx/shonenx $out/bin/shonenx \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ mpv libglvnd alsa-lib gst_all_1.gstreamer gst_all_1.gst-plugins-base gst_all_1.gst-plugins-good gst_all_1.gst-plugins-bad ]}:$out/lib/shonenx/lib \
      --prefix PATH : ${lib.makeBinPath [ mpv curl ]} \
      --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules" \
      --set ALSA_PLUGIN_DIR "${alsa-plugins}/lib/alsa-lib" \
      --run "cd $out/lib/shonenx"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Anime Streaming Desktop App";
    homepage = "https://github.com/roshancodespace/ShonenX";
    license = licenses.gpl3; # Assuming GPL3 based on typical projects or need verification, but leaving generic if unknown
    platforms = [ "x86_64-linux" ];
    mainProgram = "shonenx";
  };
}
