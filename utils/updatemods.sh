#!/bin/sh
rm -rf utils/updlog
mkdir utils/updlog
mkdir utils/updlog/mods
{ {
	exec 9<utils/updatelist
	while read name repo <&9; do
		{ {
			rm -rf mods/"$name"
			git clone --depth 1 "$repo" mods/"$name"
			cd mods/"$name"
			git submodule init
			git submodule update
			git log -1
			cd - >/dev/null
		} 2>&1; } > utils/updlog/mods/"$name" &
	done
	wait
	rm -rf $(find mods -name .git)
	rm -rf mods/zzzz_glcraft_crafthook
	mv mods/glcraft/zzzz_glcraft_crafthook mods/
	git add -A
} 2>&1; } > /dev/null
