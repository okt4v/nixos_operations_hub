# Home layout (see filestructure.txt). XDG dirs point into it so applications
# stop recreating Downloads/, Documents/ and friends.
{ config, lib, ... }:

let
  home = config.home.homeDirectory;
  dirs = [
    "doc/personal"
    "doc/work"
    "doc/school"
    "doc/notes/daily"
    "dev/active"
    "dev/work"
    "dev/finished"
    "dev/practice"
    "dev/testing"
    "dl"
    "tpl/latex"
    "med/img/shot"
    "med/img/wall"
    "med/vid/rec"
    "ent/games"
    "hkng"
    "dat/bak"
    "dat/arc"
    "dat/mkt"
    "tec/vm"
    "tec/lab"
    "tec/sftw"
  ];
in
{
  home.activation.hubDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.concatMapStringsSep " " (d: ''"${home}/${d}"'') dirs}
  '';

  # ~/fin lives inside the vault: it only resolves while the vault is open.
  home.file."fin".source = config.lib.file.mkOutOfStoreSymlink "${home}/vlt/fin";

  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    download = "${home}/dl";
    documents = "${home}/doc";
    templates = "${home}/tpl";
    pictures = "${home}/med/img";
    videos = "${home}/med/vid";
    music = "${home}/med";
    projects = "${home}/dev";
    desktop = home;
    publicShare = home;
    # also export XDG_DOWNLOAD_DIR & co. for programs that read the
    # environment instead of the file
    setSessionVariables = true;
  };

  # The same folders in the sidebar of every file dialog.
  gtk.gtk3.bookmarks = map (d: "file://${home}/${d}") [
    "dl"
    "doc"
    "dev"
    "med/img"
    "med/vid"
    "tpl"
  ];
}
