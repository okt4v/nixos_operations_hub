# Shell, terminal multiplexer, git.
{
  config,
  osConfig,
  pkgs,
  ...
}:

let
  cfg = "${osConfig.hub.dir}/config";
in
{
  # zsh and tmux only source the live files, so edits apply to the next shell.
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      source ${cfg}/zsh/init.zsh
      source ${cfg}/zsh/aliases.zsh
      # Tab completion as a fuzzy menu (must load after compinit)
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
    '';
  };

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    # Sessions (windows, panes, working directories) are saved every 10
    # minutes and restored when tmux starts after a reboot.
    plugins = with pkgs.tmuxPlugins; [
      resurrect
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];
    extraConfig = ''
      source-file ${cfg}/tmux/tmux.conf
      source-file ${cfg}/tmux/keybindings.conf
      source-file ${config.xdg.configHome}/pal/current/tmux.conf
    '';
  };

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${cfg}/nvim";

  # Shell history with directory and exit-code context. Initialised from
  # config/zsh/init.zsh; local only until a sync server exists.
  programs.atuin = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      auto_sync = false;
      update_check = false;
      filter_mode = "directory";
      style = "compact";
      inline_height = 20;
    };
  };

  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    # Identity by folder. Create the two files with a [user] section
    # (name, email, signingkey); until then the default identity applies.
    includes = [
      {
        condition = "gitdir:~/dev/work/";
        path = "~/.config/git/work";
      }
      {
        condition = "gitdir:~/doc/work/";
        path = "~/.config/git/work";
      }
      {
        condition = "gitdir:~/doc/school/";
        path = "~/.config/git/school";
      }
    ];
    settings = {
      user.name = "okt4v";
      user.email = "oktavianmayer@icloud.com";
      init.defaultBranch = "main";
      # Commits are signed with the SSH key (served by KeePassXC's agent).
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
      commit.gpgsign = true;
      tag.gpgsign = true;
      # One global pre-commit hook for every repository, see below.
      core.hooksPath = "~/.config/git/hooks";
      alias = {
        st = "status -sb";
        lg = "log --oneline --graph --decorate --all";
        undo = "reset --soft HEAD~1";
        pushf = "push --force-with-lease";
        aliases = "config --get-regexp alias";
        # git wt <branch>: new worktree next to the repo, on a new branch
        wt = "!f() { git worktree add \"../$(basename \"$PWD\")-$1\" -b \"$1\"; }; f";
      };
    };
  };

  # Blocks commits that contain something that looks like a credential, then
  # hands over to the repository's own pre-commit hook if it has one.
  xdg.configFile."git/hooks/pre-commit" = {
    executable = true;
    text = ''
      #!/bin/sh
      gitleaks git --pre-commit --staged --redact --no-banner || {
        echo "gitleaks: possible secret staged. If it is a false positive: git commit --no-verify" >&2
        exit 1
      }
      hook=$(git rev-parse --git-dir)/hooks/pre-commit
      [ -x "$hook" ] && exec "$hook" "$@"
      exit 0
    '';
  };

  home.packages = with pkgs; [
    gitleaks
    gh
    gh-dash
    gocryptfs
    libsecret # secret-tool, used by `vault`
    zoxide
    fzf
    eza
    bat
    ripgrep
    fd
    jq
    tree
    yazi
    lazygit
    glow
    fastfetch
    tldr
    navi
    ncdu
    trash-cli # `del`
    qrencode # `qr`
    zip
    unzip
    psmisc
    p7zip
  ];
}
