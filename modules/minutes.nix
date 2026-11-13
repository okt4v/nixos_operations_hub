# `minutes`: record a call (your mic and what you hear), transcribe it
# locally with whisper. The script is bin/minutes.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    whisper-cpp
    ffmpeg
  ];
}
