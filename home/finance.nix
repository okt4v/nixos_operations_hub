# Finance tools. Data lives in the vault (~/fin) and in ~/dat/mkt.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    beancount
    fava
  ];
}
