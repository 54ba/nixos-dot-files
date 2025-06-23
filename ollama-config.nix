{ config, lib, ... }: {
  services.ollama = {
    enable = true;
    acceleration = {
      backend = "cuda";
      enable = true;
    };
  };
}
