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
            rev = "1chg2qvzy1qjvdqa3pzq1hksfvsk3g8xm9r12rywmdil2rzr5frg";
            sha256 = "0fc9bdyq7wjq7azb1i62fb8v99pisihdpx5ha36cg6cm5hr6hhms";
          };
          buildInputs = with pkgs.python3.pkgs; [ daphne django_3 ];
          propagatedBuildInputs = with pkgs.python3.pkgs; [ 
            cffi markdown pyasn1 psycopg2 
          ];
          doCheck = false;
        };
      in
        pkgs.python3.withPackages (
          ps: with ps; [gunicorn django_3 hamsterdance ]
        );
    in {

      description = "hamster.dance Django application";
      environment = import ./vars.nix;
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.gettext ];
      preStart = ''
        ${djangoEnv}/usr/bin/manage.py migrate;
        # ${djangoEnv}/usr/bin/manage.py collectstatic --no-input;
      '';
      serviceConfig = {
        ExecStart = ''${djangoEnv}/bin/gunicorn \
          -b localhost \
          -p 8000 \
          hamsterdance.wsgi:application
        '';
        Restart = "always";
        RestartSec = "10s";
        WorkingDirectory = "/var/www/hamsterdance/";
      };
      unitConfig.StartLimitInterval = "1min";
    };

    services.postgresql = {
      authentication = lib.mkForce ''
        # TYPE	DATABASE	USER	ADDRESS		METHOD
        local	all		all			trust
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
      logFile = "/var/log/nginx/access.log";
      logFormat = "1";
      type = "web";
      webService = {
        enable = true;
        hostname = "hamster.dance";
        urlPrefix = "/awstats";
      };
    };
    services.awstats.enable = true;

    services.dovecot2.enable = true;
    services.postfix = {
      enable = true;
      hostname = "hamster.dance";
    };

    networking = {
      hostname = "hamster";
      domain = "hamster.dance";
      firewall.allowedTCPPorts = [ 25 80 110 143 443 465 993 ];
    };

    programs.mosh.enable = true;

    users.motd = ''
                 .     .
                (>\---/<)
                ,'     `.
               /  q   p  \
              (  >(_Y_)<  )
               >-' `-' `-<-.
              /  _.== ,=.,- \
             /,    )`  '(    )
            ; `._.'      `--<
           :     \        |  )
           \      )       ;_/  hjw
            `._ _/_  ___.'-\\\
               `--\\\

          _          _   _
         | |        | | | |
         | |     _  | | | |  __
         |/ \   |/  |/  |/  /  \_
         |   |_/|__/|__/|__/\__/
    '';

    users.users.lunasspecto = {
      description = "Dominique Cyprès";
      extraGroups = ["wheel" "dovecot2"];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCb4qUnbFGpARMrotq1xTMw3HeuPQxllFsqxaB3kRorJAISDUsEhNwEopkgvmj8QiRKowu9Znt2zMl1ZQDWiyPTZ2vlJNqvHGVUa6DDe8QqtGxFQHlxEIL6QWXGQrjFRsGKY9NjXPuAGM7lpycgf2eLEEEHf640URJbLqumBOH5E+I2vMIsd7H9a13xLiXOGq4FN87SzU2YWutrqBp40SgZ6ebEp6ETcfoj+kGgTbm7iSwzTgzBYme4Sr8thMwd9SjTIZ2y6hoombl+ZFdHJWgVWd0LXkYKwKXnwFNP7d/QfnFLrFYvkh4l6Hi/7EQC1SIDTDuZTZBG11wBPuPkPJF0iCtZ5GH8nxHEqjLkHqOamBiZ/RB8ijg/X0E6l6Jt1+ywUflijwcdxlg6joDYSUxeXdPEOeTHZFvpdlbyDOvwNMMubLowEFRPMJEf2Z2TkPZRPea3+HMs/hzX0Y1ayBRlBQXJxCsbOmA8vHhKRTb4IrjBRmzccMEPEuHQn3PU/WE= lunasspecto@slaptop"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDg7hxlbxFadIwpQ6MW7r2bT4v4KnSJNG65XfsdqUVr4PtcHIGD6zOPWbEkYehqgi/EebSG0SomNWDN/OGx/S1TT35yo4lxYkFh29rijGE5qPvHjHx+ebDIgJcMQ+28UoAmKnfGxOY8HFX7AsONw59aDo6wd8LMLO+G8lRDbVHNlIi0sr9iaQ5cd/XGuiG8ADKvZXtiy/iLdgRo34eqzBqbwYHv/YOmvzHUuoMtP9ESr7sO50BcjQ9VgckwLZ2/CiWo05naVJ6r2dJf4w+7bGUcEYKFlI2wjdRezWB8GdTOAtqYCCVk6bjCVviWiCvWzYoS7ir226w8m6FQ5tw+JQX6IRbnjSPOU412Vwoo8LN2ZkYzSP3jMib57SP82xH2+RXGzQQgtMnp6abWKaWmv2BSAt9wrN5TLdNo6+w7Q+evVdrJqDxLKDm2Kg1f8lGN2bytLT/yahW3rAphiK6xA0YQZPMrPNSboSF4TBOY7jqPTgrvo3qyif1w4z+Il3g23F8= ddelabru@ddelabru-t490s"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMFc1sNfQxETz8L7lf7ojb3iF2nFOgx91D8uGDTkKFzo JuiceSSH"
      ];
    };
    */
  };
}
