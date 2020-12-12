{ config, lib, pkgs, ... }:
{
  config = {

    # In this section we define the hamster.dance Django application
    systemd.services.hamsterdance = let
      djangoEnv = let
        hamsterdance = pkgs.python3.pkgs.buildPythonPackage rec {
          pname = "hamsterdance";
          version = "0.1.1";
          src = pkgs.fetchFromGitHub {
            owner = "ddelabru";
            repo = "hamsterdance";
            rev = "aa7e40a6a96b4167c6f8bb7481c4387079db0c3c";
            sha256 = "08hdv7fywn6s05nwgbdrzp2qw1nd9dz38m5vf61dz28b2pdn9f3f";
          };
          buildInputs = with pkgs.python3.pkgs; [ daphne django_3 ];
          propagatedBuildInputs = with pkgs.python3.pkgs; [ 
            beautifulsoup4 bleach cffi markdown pyasn1 psycopg2
          ];
          doCheck = false;
        };
      in
        pkgs.python3.withPackages (
          ps: with ps; [daphne django_3 hamsterdance]
        );
    in {
      description = "hamster.dance Django application";
      environment = import ./vars.nix;
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.gettext ];
      preStart = ''
        # ${djangoEnv}/bin/manage.py migrate;
        # ${djangoEnv}/bin/manage.py collectstatic --no-input;
      '';
      serviceConfig = {
        ExecStart = ''${djangoEnv}/bin/daphne \
          -b localhost \
          -p 8000 \
          hamsterdance.asgi:application
        '';
        Restart = "always";
        RestartSec = "10s";
        WorkingDirectory = "/var/www/hamsterdance/";
      };
      unitConfig.StartLimitInterval = "1min";
    };

    # The hamster.dance Django application uses a PostgreSQL database
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

    # In this section we define the bibliogram service
    systemd.services.bibliogram = let
      nodePackages = import ./node-composition.nix {
        inherit pkgs;
      };
    in let
      bibliogram = nodePackages."bibliogram-https://git.sr.ht/~cadence/bibliogram/archive/3af4b2f23797ae2a343097dc32557a5123105cea.tar.gz".override {
        name = "bibliogram";
        version = "1.0.0";
        src = pkgs.fetchgit {
          url = "https://git.sr.ht/~cadence/bibliogram";
          rev = "3af4b2f23797ae2a343097dc32557a5123105cea";
          sha256 = "0lnn648h96w103m4zizns3sn81zzkjj80gnlbmbyw1gkghmpn495";
        };
        nativeBuildInputs = [pkgs.coreutils pkgs.makeWrapper];
        postInstall = let
          nodejs = pkgs.nodejs-12_x;
        in ''
          mkdir -p /var/lib/bibliogram
          ln -sfT /var/lib/bibliogram db
          echo 'module.exports = {
            tor: {
              enabled: true
            },
            feeds: {
              enabled: true
            },
            caching: {
              db_post_n3: false
            },
            website_origin: "https://bibliogram.hamster.dance"
          }' > config.js
          cp -R ./* $out/lib/
          makeWrapper ${nodejs}/bin/npm $out/bin/bibliogram \
            --run "cd $out/lib/" \
            --prefix PATH : ${lib.makeBinPath [nodejs pkgs.bash]}
        '';
      };
    in {
      description = "bibliogram application";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.gettext ];
      serviceConfig = {
        ExecStart = ''${bibliogram}/bin/bibliogram start
        '';
        Restart = "always";
        RestartSec = "10s";
        User = "bibliogram";
      };
      unitConfig.StartLimitInterval = "1min";
    };

    environment.systemPackages = with pkgs; [
      git mutt neofetch python3 tldr vim
    ];
    services.nginx.package = pkgs.nginx.override {
      modules = [ pkgs.nginxModules.ipscrub ];
    };
    services.nginx.commonHttpConfig = ''
      log_format scrubbed '$remote_addr_ipscrub - $remote_user [$time_local] '
                          '"$request" $status $body_bytes_sent '
                          '"$http_referer" "$http_user_agent"';
    '';
    services.nginx.virtualHosts = {  
      "hamster.dance" = {
        addSSL = true;
        enableACME = true;
        forceSSL = false;
        extraConfig = ''
          location / {
              root /var/www/hamsterdance/;
          }
          location /admin/ {
              proxy_pass http://localhost:8000/admin/;
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
          access_log /var/log/nginx/access.log scrubbed;
        '';
      };
      "www.hamster.dance" = {
        addSSL = true;
        enableACME = true;
        forceSSL = false;
        globalRedirect = "hamster.dance";
      };
      "bibliogram.hamster.dance" = {
        addSSL = true;
        enableACME = true;
        forceSSL = false;
        extraConfig = ''
          location / {
            proxy_pass http://localhost:10407/;
            access_log off;
          }
        '';
      };
    };
    services.nginx.enable = true;

    security.acme = {
      acceptTerms = true;
      email = "lunasspecto@gmail.com";
    };

    services.awstats.configs."hamster.dance" = {
      domain = "hamster.dance";
      extraConfig = { IncludeInternalLinksInOriginSection = "0"; };
      hostAliases = [ "hamster.dance" "www.hamster.dance" ];
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
    services.awstats.updateAt = "hourly";

    services.molly-brown = {
      enable = true;
      hostName = "hamster.dance";
      port = 1965;
      docBase = "/var/gemini/";
      certPath = "/var/lib/acme/hamster.dance/cert.pem";
      keyPath = "/var/lib/acme/hamster.dance/key.pem";
      settings = {
        CGIPaths = [ "/var/gemini/cgi-bin/" ];
      };
    };
    systemd.services.molly-brown.serviceConfig.SupplementaryGroups = [
      config.security.acme.certs."hamster.dance".group
    ];

    services.dovecot2 = {
      enable = true;
      sslServerCert = "/var/lib/acme/hamster.dance/cert.pem";
      sslServerKey = "/var/lib/acme/hamster.dance/key.pem";
      extraConfig = ''
        service auth {
          unix_listener /var/lib/postfix/queue/private/auth {
            mode = 0660
            user = postfix
            group = postfix
          }
        }
        auth_mechanisms = plain login
      '';
    };
    services.postfix = {
      enable = true;
      enableSubmission = true;
      enableSubmissions = true;
      hostname = "hamster.dance";
      sslCert = "/var/lib/acme/hamster.dance/cert.pem";
      sslKey = "/var/lib/acme/hamster.dance/key.pem";
      submissionOptions = {
        smtpd_sasl_auth_enable = "yes";
        smtpd_sasl_type = "dovecot";
        smtpd_sasl_path = "private/auth";
        smtpd_recipient_restrictions = "permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination";
      };
      submissionsOptions = {
        smtpd_sasl_auth_enable = "yes";
        smtpd_sasl_type = "dovecot";
        smtpd_sasl_path = "private/auth";
        smtpd_recipient_restrictions = "permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination";
        smtpd_tls_wrappermode = "yes"; 
      };
    };

    networking = {
      hostName = "hamster";
      domain = "hamster.dance";
      firewall.allowedTCPPorts = [ 25 80 110 143 443 465 587 993 1965 ];
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
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCb4qUnbFGpARMrotq1xTMw3HeuPQxllFsqxaB3kRorJAISDUsEhNwEopkgvmj8QiRKowu9Znt2zMl1ZQDWiyPTZ2vlJNqvHGVUa6DDe8QqtGxFQHlxEIL6QWXGQrjFRsGKY9NjXPuAGM7lpycgf2eLEEEHf640URJbLqumBOH5E+I2vMIsd7H9a13xLiXOGq4FN87SzU2YWutrqBp40SgZ6ebEp6ETcfoj+kGgTbm7iSwzTgzBYme4Sr8thMwd9SjTIZ2y6hoombl+ZFdHJWgVWd0LXkYKwKXnwFNP7d/QfnFLrFYvkh4l6Hi/7EQC1SIDTDuZTZBG11wBPuPkPJF0iCtZ5GH8nxHEqjLkHqOamBiZ/RB8ijg/X0E6l6Jt1+ywUflijwcdxlg6joDYSUxeXdPEOeTHZFvpdlbyDOvwNMMubLowEFRPMJEf2Z2TkPZRPea3+HMs/hzX0Y1ayBRlBQXJxCsbOmA8vHhKRTb4IrjBRmzccMEPEuHQn3PU/WE= lunasspecto@slaptop"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDg7hxlbxFadIwpQ6MW7r2bT4v4KnSJNG65XfsdqUVr4PtcHIGD6zOPWbEkYehqgi/EebSG0SomNWDN/OGx/S1TT35yo4lxYkFh29rijGE5qPvHjHx+ebDIgJcMQ+28UoAmKnfGxOY8HFX7AsONw59aDo6wd8LMLO+G8lRDbVHNlIi0sr9iaQ5cd/XGuiG8ADKvZXtiy/iLdgRo34eqzBqbwYHv/YOmvzHUuoMtP9ESr7sO50BcjQ9VgckwLZ2/CiWo05naVJ6r2dJf4w+7bGUcEYKFlI2wjdRezWB8GdTOAtqYCCVk6bjCVviWiCvWzYoS7ir226w8m6FQ5tw+JQX6IRbnjSPOU412Vwoo8LN2ZkYzSP3jMib57SP82xH2+RXGzQQgtMnp6abWKaWmv2BSAt9wrN5TLdNo6+w7Q+evVdrJqDxLKDm2Kg1f8lGN2bytLT/yahW3rAphiK6xA0YQZPMrPNSboSF4TBOY7jqPTgrvo3qyif1w4z+Il3g23F8= ddelabru@ddelabru-t490s"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMFc1sNfQxETz8L7lf7ojb3iF2nFOgx91D8uGDTkKFzo JuiceSSH"
      ];
    };
    users.users.django = {};
    users.users.bibliogram = {};

    programs.zsh.enable = true;
    users.users.spiritomb = {
      description = "Hezekiah Sudol";
      isNormalUser = true;
      extraGroups = ["wheel" "dovecot2"];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCt9tY9QPlN9QLkxX83/ID51qt1/ZJriBT9GmuIZ6PuSNzG8e60089L32foB8PP3VWsVxS4w6etGtL62d/NTbWUMFMW+KbWyKhwH0GM5CIqyv2knA+7B3M2EgBDei7qM0u7kQllfq2qa+Xr0X0B7FauL9qbIVl4aXecs6KstbWBRSZxKDugZakjnAwckSBY/kgAg/8ctUOkIam0mSELRnmY6pvFnLow+Fh+V5Rlm6ooi3jKHq4eRRCZqIpd91cA53BYACisTMTFrQaVP1CFQcm96gq0fFzCV6M++S6uK8ewMyyNI5cBPLMrbb7Ih4X86KTTCAEfV+/ypmIpNzB6KtZLLePfA+4dBtMZxkRdUdN/NSQW5IKUlDqZ8a0HW9EmPUyPoa3cd4CFIQ5dFjtrX5xUOv6KhI73OjKwgtyCyhQ4dRDzhsLj/lBQcHnPTsRBUBxjHazAVDypYgb6CpRps8zv+EUIUe6bdiMn2oYpfimHoWqwWksLXm+rX/xM9maxjY4hdLk+Erit4quQDb/vs6NTfFgVuCJIzTWaGeICGL1HHk2AplDG2YlgMN4jEwPRi81s5ewA/m+yNRVGhZpO4FvK9oRsGcEMRThunX9XUmwPGc8vzLO2iHOeERS8+I6mR2YnsxcBUt7RB6bre5ixhAo+uZqGlAhgttbbk5nUMJ4ebw== JuiceSSH"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC280fonA8J7Q14TFS7TnF7mKBMrLgPxy1yL0jeVfZ6Q0KyMGehKMVM58vuyqPxvzTQXncu35N+VYfF46rv+tfzNT7z1JEhxKkNB1B6KVvPjHyRfaBJ4fxUMzmNJYptOE/1dxHW0pcqtbj67Cc5nMI082Ku4wnsuMzE+jkU6JNcpUT473wrm2lnaCAhiJcUcLVVhuCq2WFLOgk8idZZFpZKDmPmWKkG1zMHe5M1/rygAc6fZlGMgHPxjL/M3/JsL6X/ujV9C8IQhr6xTKQi/aglQfpreQ9u0GCRCfmkGBYhS5Ncc4geDzjxPohCVEjhGXe9LXp8pwrbOUpwjv2b4kWB u0_a121@localhost"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8kbQmIPumfOLbDQb6igdKbMTCvpoXNRi7eX8Bhs+0i5jX2Bb5CgzOf+ZrHp2r93/aH//JQ4zaEf1y/+q/nBzEZsUPtEYxvgiQhjdUeNeeLWPRXj6679cGZIXBns62682qMJ4X2kvq8AbcMyljipl3OGOCbH8oSBFUV2JQ5NiMpkjUncaoPFzrdDdg9ur9N4D6N7++H4VNmHaTTGl14TkKJS0vl8ETxXtTzsHgta6BLh86dTRq2SSgBdUGO3Lzm14RAWX0bwM9WbHjIdE+hxyqXUmtaG2C7Qncubs2kpWYoSvVOZZ1Wct/g+akWNga6qzECOlVN6/y528Wby+BhnHf spiritomb@computerbox"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTUtN/5XbJ2FlaTzWCufRS0mbSRF9jxCgzsp8PghkOJdOBFqeZ4DUZWljrv6gFblfbak2KmqRg633czxx8YYC+ujwB+s+gB8JnhusjfZKbUVGTQA2mugcgtYXIAnFga6jOQbDeAf0xSh7DTj2VkGEoZGgclJmszP2zdwTTM7UiNsPQHP76WdF7k/tWnpvbggMbhbPqMDmW0hI/wBIBISUOwVMMJ4lFEoByeAZ64KVA+Uv/A4k68WCcDq0wAJJXLd6eN6K9eV9oP89gvw+1toM09tx4R3uAxwWUUN8fBjzIIk2w0iz1nlOmSIfJmkLbC4Ny/mWvRZEDNqkf+pBjMPOCJ5jMdjgIhWVG26Izg/3rQxLgnVZO/T73nOJo9+mBYp+QNoL1G7ndz6mAZBO7jhv/LR8i1qfRQH83kavwd9+QsMkp4VjBJkzGHa4AqT7I7ta3PNtZ34gL7dO/il5ATIwK9hTv0VSMY9azL/nl8mPA1w9OOHUyq7HvHnCLDZIOXMStKIdSLcYaOSsWpo/GZ5O8WMwczb4otpyNG4WTCeT+wjcSXFjW6RtvWKijLI2CP3HPr3SGlpRqtZJ+KotNt7E/ee/FlON1eBHUPyK1hheJ6qj/IaWvty0Xsu7rF5Epswcs4XKW/k35IJBGmBi2Zagfk+2hz3fIdUsy35b/hVDygQ== oneplus"
      ];
    };
  };
}
