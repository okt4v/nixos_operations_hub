# Editor tooling and global dev tools. Project libraries do NOT go here:
# they belong in the project's devshell (see templates/).
{ pkgs, unstable, ... }:

{
  home.packages = with pkgs; [
    # LSP servers (nvim needs these everywhere)
    pyright
    clang-tools
    gopls
    bash-language-server
    vscode-langservers-extracted
    yaml-language-server
    taplo
    lua-language-server
    texlab
    asm-lsp
    typescript-language-server
    typescript
    emmet-language-server
    nil
    tree-sitter # nvim-treesitter builds its parsers with it
    # Formatters
    stylua
    ruff
    prettier
    shfmt
    nixfmt
    shellcheck
    # Toolchains that are fine to have globally
    gcc
    gnumake
    cmake
    ninja
    gdb
    binutils
    pkg-config
    go
    nodejs
    uv
    # nvim's Python host: pynvim for molten-nvim, jupyter for its kernels
    (python3.withPackages (
      ps: with ps; [
        pynvim
        jupyter
        jupyter-client
      ]
    ))
    # Ops, for the machines that are not NixOS
    ansible
    opentofu
    kubectl
    k9s
    # Tools
    devenv
    unstable.claude-code # moves fast; stable lags ~100 versions
    duckdb
    age
    sops
    texlive.combined.scheme-full
    pandoc # also `untex`
    llama-cpp # llama-server, needed by `untex`
  ];

  home.sessionVariables.GOPATH = "$HOME/.local/share/go";
}
