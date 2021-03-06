# This is an example of what downstream consumers of holonix should do
# This is also used to dogfood as many commands as possible for holonix
# For example the release process for holonix uses this file
let

 # point this to your local config.nix file for this project
 # example.config.nix shows and documents a lot of the options
 config = import ./config.nix;

 # START HOLONIX IMPORT BOILERPLATE
 holonix = import (
  if ! config.holonix.use-github
  then config.holonix.local.path
  else fetchTarball {
   url = "https://github.com/${config.holonix.github.owner}/${config.holonix.github.repo}/tarball/${config.holonix.github.ref}";
   sha256 = config.holonix.github.sha256;
  }
 ) { config = config; };
 # END HOLONIX IMPORT BOILERPLATE

 target-os = if holonix.pkgs.stdenv.isDarwin then "darwin" else "linux";
 config-uri = if holonix.pkgs.stdenv.isDarwin then "Library/Application\\ Support" else ".config";

in
with holonix.pkgs;
{
 dev-shell = stdenv.mkDerivation (holonix.shell // {
  name = "dev-shell";

  shellHook = holonix.pkgs.lib.concatStrings [''
  ln -sf ${holonix.holochain.holochain}/bin/holochain holochain-${target-os}
  ln -sf ${holonix.holochain.hc}/bin/hc hc-${target-os}
  ${holonix.pkgs.nodejs}/bin/npm install
  ${holonix.pkgs.nodejs}/bin/npx webpack
  export PATH="$PATH:$( ${holonix.pkgs.nodejs}/bin/npm bin )"
  ''
  holonix.shell.shellHook
  ];
  HOLOSCAPE_CONFIG_URI = config-uri;

  DEV="true";

  buildInputs = [
   holonix.pkgs.unzip
   holonix.pkgs.electron_6

   (holonix.pkgs.writeShellScriptBin "holoscape" ''
   ${holonix.pkgs.electron_6}/bin/electron .
   '')

   (holonix.pkgs.writeShellScriptBin "holoscape-flush" ''
   set -euxo pipefail
   rm -rf $HOME/${config-uri}/holoscape
   rm -rf $HOME/${config-uri}/Holoscape-default
   rm -rf ./Holoscape-linux-x64
   rm -rf ./Holoscape-darwin-x64
   rm -rf ./node_modules
   rm -rf ./package-lock.json
   '')
  ]
   ++ holonix.shell.buildInputs
  ;
 });
}
