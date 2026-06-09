{ pkgs, ... }:

{

  fonts.packages = with pkgs; [
  	noto-fonts
	noto-fonts-color-emoji
	nerd-fonts.jetbrains-mono
	nerd-fonts.symbols-only
	jetbrains-mono
  ];

}
