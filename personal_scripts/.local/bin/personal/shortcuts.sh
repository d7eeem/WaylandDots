#!/bin/sh

bmdirs="${XDG_CONFIG_HOME:-$HOME/.config}/shell/bm-dirs"
bmfiles="${XDG_CONFIG_HOME:-$HOME/.config}/shell/bm-files"

# Output locations. Unactivated progs should go to /dev/null.
shell_shortcuts="${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc"
shell_env_shortcuts="${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc"
fish_shortcuts="${XDG_CONFIG_HOME:-$HOME/.config}/fish/shorts.fish"
zsh_named_dirs="/dev/null"
lf_shortcuts="/dev/null"
vim_shortcuts="/dev/null"
ranger_shortcuts="/dev/null"
qute_shortcuts="/dev/null"
vifm_shortcuts="/dev/null"
#shell_shortcuts="/dev/null"
#zsh_named_dirs="${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc"
#vim_shortcuts="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/shortcuts.vim"
#lf_shortcuts="${XDG_CONFIG_HOME:-$HOME/.config}/lf/shortcutrc"

# Remove, prepare files
rm -f "$lf_shortcuts" "$ranger_shortcuts" "$qute_shortcuts" "$zsh_named_dirs" "$vim_shortcuts" "$fish_shortcuts" 2>/dev/null
printf "# vim: filetype=sh\\n" > "$fish_shortcuts"
printf "# vim: filetype=sh\\n" > "$shell_shortcuts"
printf "\" vim: filetype=vim\\n" > "$vifm_shortcuts"

# Format the `directories` file in the correct syntax and sent it to all three configs.
eval "echo \"$(cat "$bmdirs")\"" | \
awk "!/^\s*#/ && !/^\s*\$/ {gsub(\"\\\s*#.*$\",\"\");
	printf(\"abbr %s \42cd %s && ls -A\42\n\", \$1, \$2)   >> \"$shell_shortcuts\" ;
	printf(\"[ -n \42%s\42 ] && export %s=\42%s\42 \n\",\$1,\$1,\$2)   >> \"$shell_env_shortcuts\" ;
	printf(\"hash -d %s=%s \n\",\$1,\$2)                 >> \"$zsh_named_dirs\"  ;
	printf(\"abbr %s \42cd %s; and ls -A\42\n\",\$1,\$2) >> \"$fish_shortcuts\"  ;
	printf(\"map g%s :cd %s<CR>\nmap t%s <tab>:cd %s<CR><tab>\nmap M%s <tab>:cd %s<CR><tab>:mo<CR>\nmap Y%s <tab>:cd %s<CR><tab>:co<CR> \n\",\$1,\$2, \$1, \$2, \$1, \$2, \$1, \$2)       >> \"$vifm_shortcuts\" ;
	printf(\"config.bind(';%s', \42set downloads.location.directory %s ;; hint links download\42) \n\",\$1,\$2) >> \"$qute_shortcuts\" ;
	printf(\"map C%s cd \42%s\42 \n\",\$1,\$2)           >> \"$lf_shortcuts\" ;
	printf(\"cmap ;%s %s\n\",\$1,\$2)                    >> \"$vim_shortcuts\" }"

# Format the `files` file in the correct syntax and sent it to both configs.
eval "echo \"$(cat "$bmfiles")\"" | \
awk "!/^\s*#/ && !/^\s*\$/ {gsub(\"\\\s*#.*$\",\"\");
  printf(\"abbr %s \42nvim %s\42 \n\",\$1,\$2) >> \"$shell_shortcuts\"  ;
	printf(\"[ -n \42%s\42 ] && export %s=\42%s\42 \n\",\$1,\$1,\$2)   >> \"$shell_env_shortcuts\" ;
  printf(\"abbr %s \42nvim %s\42 \n\",\$1,\$2) >> \"$fish_shortcuts\"  ;
	printf(\"map E%s \$\$EDITOR \42%s\42 \n\",\$1,\$2)   >> \"$lf_shortcuts\" ;
	printf(\"cmap ;%s %s\n\",\$1,\$2)                    >> \"$vim_shortcuts\" }"



	#printf(\"abbr %s \42%s %s\42\n\", \$1, editor, \$2)  >> \"$shell_shortcuts\" ;
