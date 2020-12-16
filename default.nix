# This file is for standing up a development environment with nix-shell
{ pkgs ? import <nixpkgs> {} }:

pkgs.python3Packages.buildPythonApplication {
  pname = "hamsterdance";
  src = ./.;
  version = "0.1";
  propagatedBuildInputs =  with pkgs.python3Packages; [
    beautifulsoup4 bleach cffi daphne markdown pyasn1 psycopg2 django_3
  ];
}
