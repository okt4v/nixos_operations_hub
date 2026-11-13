# Local LLM (ollama on the Radeon iGPU via ROCm). Off by default: the ROCm
# build is several GB.   hub.ai.enable = true;
# Then: `ollama pull llama3.2:3b`, `ask "..."`, and :Ask in nvim.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.hub.ai.enable = lib.mkEnableOption "local LLM service (ollama)";

  config = lib.mkIf config.hub.ai.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      # ponytail: the 680M (gfx1035) is not on ROCm's list; this makes it
      # accept the GPU. If generation is broken, use pkgs.ollama (CPU).
      rocmOverrideGfx = "10.3.0";
    };
  };
}
