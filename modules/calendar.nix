{ ... }:

{

  services.rustical = {
    enable = true;
    settings.http.bind = "0.0.0.0:4000";
  };

}
