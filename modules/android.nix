{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    android-tools
    scrcpy
    qtscrcpy
    android-file-transfer
  ];

}
