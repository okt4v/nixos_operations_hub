# Calls and recording: a noise-suppressed virtual microphone and OBS with a
# virtual camera. Screen sharing works through the wlr portal that sway's
# module already enables. (The E16 has a physical camera shutter, so there
# is no software camera switch.)
{ pkgs, ... }:

{
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };

  # Adds the input device "Noise-cancelled mic"; pick it in the call app.
  services.pipewire.extraConfig.pipewire."99-rnnoise" = {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "Noise-cancelled mic";
          "media.name" = "Noise-cancelled mic";
          "filter.graph".nodes = [
            {
              type = "ladspa";
              name = "rnnoise";
              plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
              label = "noise_suppressor_mono";
              control."VAD Threshold (%)" = 50.0;
            }
          ];
          "capture.props" = {
            "node.name" = "rnnoise_capture";
            "node.passive" = true;
          };
          "playback.props" = {
            "node.name" = "rnnoise_mic";
            "media.class" = "Audio/Source";
          };
        };
      }
    ];
  };
}
