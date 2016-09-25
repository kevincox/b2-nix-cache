with import <nixpkgs> {};

stdenv.mkDerivation {
	name = "b2-nix-cache";
	
	meta = {
		description = "Tool to upload Nix closures to a b2 binary cache.";
		homepage = https://github.com/kevincox/b2-nix-cache;
	};
	
	src = builtins.filterSource (name: type:
		(lib.hasPrefix (toString ./b2-nix-cache.sh) name)
	) ./.;
	
	__noChroot = true;
	SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
	
	buildInputs = [ makeWrapper ];
	
	installPhase = ''
		install -Dm755 b2-nix-cache.sh "$out/bin/b2-nix-cache"
		wrapProgram $out/bin/b2-nix-cache \
			--set PATH ${lib.makeBinPath [
				coreutils
				backblaze-b2
				nix
			]}
	'';
}
