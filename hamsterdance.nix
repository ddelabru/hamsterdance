{ config, lib, pkgs, ... }:
{
  imports = [
    ./vars.nix
  ];
  config = {  
    systemd.services.hamsterdance = let
      djangoEnv = let
        hamsterdance = pkgs.python3.pkgs.buildPythonPackage rec {
          pname = "hamsterdance";
          version = "0.1.1";
          src = pkgs.fetchFromGitHub {
            owner = "ddelabru";
            repo = "hamsterdance";
            rev = "d0df0dc569a6b6bb72dd58b8f5153d4bf82bdcb6";
            sha256 = "02jjq2bmfsn8anwvarsvdyx7b6r2q5j02a3i8vl4bpwnny2hhms8";
          };
          buildInputs = with pkgs.python3.pkgs; [ daphne django ];
          propagatedBuildInputs = with pkgs.python3.pkgs; [ 
            cffi markdown pyasn1 psycopg2 
          ];
          doCheck = false;
        };
      in
        pkgs.python3.withPackages (ps: with ps; [daphne django hamsterdance ]);
    in {
      description = "hamster.dance Django application";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.gettext ];
      preStart = ''
        ${djangoEnv}/bin/python manage.py migrate;
        # ${djangoEnv}/bin/python manage.py collectstatic --no-input;
      '';
      serviceConfig = {
        WorkingDirectory = "/var/www/hamsterdance/";
        ExecStart = ''${djangoEnv}/bin/daphne \
          -b localhost \
          -p 8000 \
          hamsterdance.asgi:application
        '';
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
      };
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = ["hamsterdance"];
    };

    /*
    services.nginx.virtualHosts = {  
      "hamster.dance" = {
        enableACME = true;
        forceSSL = false;
        extraConfig = ''
          location / {
              root /var/www/hamsterdance/;
          }
          location /blog/ {
              proxy_pass http://localhost:8000/blog/;
          }
          location /guestbook/ {
              proxy_pass http://localhost:8000/guestbook/;
          }
          location /podcast/ {
              proxy_pass http://localhost:8000/podcast/;
          }
        '';
      };
      "www.hamster.dance" = {
        enableACME = true;
        forceSSL = false;
        globalRedirect = "hamster.dance";
      };
    };
    services.nginx.enable = true;

    services.awstats.configs."hamsterdance" = {
      domain = "hamster.dance";
      hostAliases = [ "www.hamster.dance" ];
      logFile = "/var/log/nginx/access.log"
      logFormat = "1"
      type = "web";
      webService = {
        enable = true;
        hostname = "hamster.dance";
        urlPrefix = "/awstats";
      };
    };
    services.awstats.enable = true;

    services.dovecot2.enable = true;
    services.postfix.enable = true;

    networking.firewall.allowedTCPPorts = [ 25 80 110 143 443 465 993 ];
    */
  };
}
