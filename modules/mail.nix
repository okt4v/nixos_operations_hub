# Mail in the terminal: aerc, talking IMAP directly (nothing is synced to
# disk). Accounts are in config/aerc/accounts.conf; the password is the same
# app-specific secret `icloud` the calendar uses. `email --bar` feeds the
# unread count in the bar.
{ pkgs, ... }:

{
  sops.secrets.icloud.owner = "oktav";
  environment.systemPackages = [ pkgs.aerc ];
}
