{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "diesel-tracing-dev-env";
  buildInputs = with pkgs; [
    cargo
    rustc
    rustfmt
    clippy
    
    pkg-config
    postgresql
    libmysqlclient
    sqlite
  ];

  LD_LIBRARY_PATH = "${pkgs.postgresql.lib}/lib";
}
