{ config, lib, pkgs, ... }:
{
  config = {  
    systemd.services.hamsterdance = let
      djangoEnv = let
        hamsterdance = pkgs.python3.pkgs.buildPythonPackage rec {
          pname = "hamsterdance";
          version = "0.1.1";
          src = pkgs.fetchFromGitHub {
            owner = "ddelabru";
            repo = "hamsterdance";
            rev = "cc43a2b03f4496ee7280f88a8ca75a906df40dbf";
            sha256 = "00rkkjlmi6zj99jh8v9w36isq66i6nybs0hh6var92l3zy1x63b5";
          };
          buildInputs = with pkgs.python3.pkgs; [ daphne django ];
          propagatedBuildInputs = with pkgs.python3.pkgs; [ 
            cffi markdown pyasn1 psycopg2 
          ];
          doCheck = false;
        };
      in
        pkgs.python3.withPackages (ps: with ps; [gunicorn django hamsterdance ]);
    in {
      description = "hamster.dance Django application";
      environment = import ./vars.nix;
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.gettext ];
      preStart = ''
        # ${djangoEnv}/bin/python manage.py migrate;
        # ${djangoEnv}/bin/python manage.py collectstatic --no-input;
      '';
      serviceConfig = {
        ExecStart = ''${djangoEnv}/bin/gunicorn \
          -b localhost \
          -p 8000 \
          hamsterdance.wsgi:application
        '';
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
      };
    };

    services.postgresql = {
      authentication = lib.mkForce ''
        # TYPE	DATABASE	USER	ADDRESS		METHOD
        local	all		all			peer
        host	all		all	127.0.0.1/32	password
        host	all		all	::1/128		password
      '';
      enable = true;
      ensureDatabases = ["hamsterdance"];
      identMap = "map-name root postgres";
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
