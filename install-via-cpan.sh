#!/bin/bash
set -x

if command -v cygpath 2>/dev/null; then
  cygpath_helper() {
    cygpath.exe -w "$1" |
    perl -pe 's#\\#\\\\#g'
  }
else
  cygpath_helper() {
    echo "$1"
  }
fi

echo "$broken_log"
mount
env
unset LD_PRELOAD
cygpath=$(command -v cygpath 2>/dev/null || true)
if [ -n "$cygpath" ]; then
  current_perl=$(command -v perl 2>/dev/null || true)
  "$cygpath" -w "$current_perl" | grep Git || true
  view_bin=$(cygpath -w /bin)
  view_tmp=$(cygpath -w /tmp)
  view_usr=$(cygpath -w /usr)
  view_usr_bin=$(cygpath -w /usr/bin)
  view_usr_lib=$(cygpath -w /usr/lib)
  view_usr_share=$(cygpath -w /usr/share)
  perl -V
fi

cpanm_log=$(mktemp)
mv "$cpanm_log" "$HOME"
cpanm_log="$HOME/$(basename "$cpanm_log")"
if [ -n "$TEMP" ] && [ -n "$temp" ] && [ "$TEMP" != "$temp" ]; then
  TEMP="$temp"
fi
cpanm_command=$(command -v cpanm)
(
  echo "$perl_libs" |
  xargs perl "$cpanm_command" --verbose --notest 2>&1
) |
  tee "$cpanm_log" ||
  true

echo "$broken_log"
interesting=$(find $(perl -e 'print qq(@INC)') -name ExtUtils 2>/dev/null || true)
if [ -d "$interesting" ]; then
  ls "$interesting"
fi
needed_perl_libs=$(mktemp)
mkdir_shim=$(mktemp -d)
cp "$spellchecker/mkdir" "$mkdir_shim"
PATH="$mkdir_shim:$PATH"
for attempt in $(seq 3); do
echo "attempt: $attempt"

select_perl_libs() {
  rm -f "$needed_perl_libs"
  for perl_lib_requested in $perl_libs; do
    perl "-M$perl_lib_requested" -e1 2>/dev/null || echo "$perl_lib_requested" >> "$needed_perl_libs"
  done
}
select_perl_libs

if [ -s "$needed_perl_libs" ]; then
  cpanm_work=$(perl -ne '
    if (m{^Work directory is (.*)}) {
      print $1;
      last;
    }
    if (m{^See (.*?)/build.log for details}) {
      print $1;
      last;
    }
  ' "$cpanm_log" | head -1)
  (
    if ! cd "$(cygpath_helper "$cpanm_work")"; then
      echo "::error ::Could not recover from cpanm failures -- this is probably fatal"
    else
      available_modules=$(
        perl -ne 'next unless s{^name:\s+}{};s/-/::/g; print' */META.yml
      )
      cpanm_modules=$(
        for cpanm_module in $available_modules; do
          perl -M"$cpanm_module" -e 1 >/dev/null 2>/dev/null || echo "$cpanm_module"
        done
      )
      for cpanm_module in $(echo $cpanm_modules $(cat $needed_perl_libs) | xargs -n1 | sort -u); do (
        cpanm_module_with_star=$(echo "$cpanm_module" | perl -pe 's/::/-/g;s<$><*/>')
        cpanm_module_expanded=$(eval echo "$cpanm_module_with_star")
        if [ -d "$cpanm_module_expanded" ]; then
          cpanm_module="$cpanm_module_expanded"
        else
          perl "$cpanm_command" --verbose --notest "$cpanm_module" || true
        fi

        if [ -d "$cpanm_module" ]; then
          cd "$cpanm_module"
          if [ ! -e Makefile ] && [ -e Makefile.PL ]; then
            makefile_pl_log=$(mktemp)
            perl -I'inc' Makefile.PL |
              tee "$makefile_pl_log" ||
              true
            perl -ne 'next unless m{you may need to install the (\S+) module}; print' "$makefile_pl_log" >> "$needed_perl_libs"
          fi
          ok=
          if [ -f Makefile ]; then
            "$spellchecker/fix-cpan-makefile.pl" Makefile
            make &&
              make install &&
              ok=1
          fi
          if [ -z "$ok" ]; then
            echo "Could not build $cpanm_module -- this is probably fatal"
          fi
        fi
      ); done
    fi
  )
  select_perl_libs
fi
sleep 2
done
