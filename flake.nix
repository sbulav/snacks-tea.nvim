{
  description = "snacks-tea.nvim demo environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              bashInteractive
              git
              neovim
              vhs
              asciinema
              python3
            ];
          };
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          demoScript = pkgs.writeShellApplication {
            name = "demo";
            runtimeInputs = [ pkgs.neovim ];
            text = ''
              if [ ! -f "demo/demo.lua" ]; then
                echo "Run this command from the snacks-tea.nvim repository root."
                exit 1
              fi
              exec nvim -u demo/demo.lua
            '';
          };

          recordScript = pkgs.writeShellApplication {
            name = "record-demo";
            runtimeInputs = [
              pkgs.vhs
              pkgs.neovim
            ];
            text = ''
              if [ ! -f "demo/record.tape" ]; then
                echo "Run this command from the snacks-tea.nvim repository root."
                exit 1
              fi
              exec vhs demo/record.tape
            '';
          };
        in
        {
          demo = {
            type = "app";
            program = "${demoScript}/bin/demo";
          };

          record-demo = {
            type = "app";
            program = "${recordScript}/bin/record-demo";
          };

          default = {
            type = "app";
            program = "${recordScript}/bin/record-demo";
          };
        }
      );
    };
}
