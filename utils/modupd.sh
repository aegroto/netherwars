name="$1"
repo="$2"
{ {
	rm -rf mods/"$name"
	git clone --depth 1 "$repo" mods/"$name"
	cd mods/"$name"
	git submodule init
	git submodule update
	git log -1
	cd - >/dev/null
} 2>&1; } > utils/updlog/mods/"$name" &
