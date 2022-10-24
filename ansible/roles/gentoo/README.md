* one node acts as builder, the others are consumers only which require the following entries in make.conf:
PORTAGE_BINHOST="ssh://<package builder user>@<package builder host>/var/cache/binpkgs"
EMERGE_DEFAULT_OPTS="--usepkgonly --getbinpkgonly"
