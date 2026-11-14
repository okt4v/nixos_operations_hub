# `minutes`: record a call (your mic and what you hear), transcribe it
# locally with whisper. The script is bin/minutes. `dictate` uses the same
# model to type what you say.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    whisper-cpp
    ffmpeg
    wtype # `dictate` types the text
  ];
}
