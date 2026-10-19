# Shared by login, interactive, and non-interactive shells. No subprocesses.
for _wb_bin in /usr/local/sbin /usr/local/bin /opt/homebrew/sbin /opt/homebrew/bin \
  "$HOME/.local/bin" "$HOME/.local/share/mise/shims"; do
  if [ -d "$_wb_bin" ]; then
    # Move each managed path to the front even after macOS path_helper reorders it.
    _wb_rest=$PATH
    _wb_clean=
    while [ -n "$_wb_rest" ]; do
      _wb_part=${_wb_rest%%:*}
      case "$_wb_rest" in *:*) _wb_rest=${_wb_rest#*:} ;; *) _wb_rest= ;; esac
      if [ "$_wb_part" != "$_wb_bin" ]; then
        _wb_clean=${_wb_clean:+$_wb_clean:}$_wb_part
      fi
    done
    PATH=$_wb_bin${_wb_clean:+:$_wb_clean}
  fi
done
unset _wb_bin _wb_rest _wb_clean _wb_part
export PATH
