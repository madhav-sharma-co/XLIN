# XLIN Terminal shell: a clean prompt and a small welcome card.
# Loaded by ~/.config/bashrc/99-xlin (or ~/.bashrc). Colours use the terminal's own palette,
# so everything follows `xlin theme light|dark` by itself.
#
#   xlin terminal banner off     hide the welcome card      (on = show it again)
#   xlin-banner                  show the card now
case $- in *i*) ;; *) return 0 ;; esac
[[ -n "${XLIN_SHELL_LOADED:-}" ]] && return 0
XLIN_SHELL_LOADED=1

# ------------------------------------------------------------------ prompt
# Other prompt tools (oh-my-posh, starship) are switched off for this shell only.
__xlin_neutralize() {
  local -a out=()
  local c
  for c in "${PROMPT_COMMAND[@]}"; do
    c=${c//_omp_hook/:}
    c=${c//starship_precmd/:}
    out+=("$c")
  done
  PROMPT_COMMAND=("${out[@]}")
}

PROMPT_DIRTRIM=3
__xlin_first_prompt=1

__xlin_prompt() {
  local ec=$?            # first line: the exit status of your last command
  local blue='\[\e[1;34m\]' dim='\[\e[90m\]' cyan='\[\e[36m\]' red='\[\e[31m\]' rst='\[\e[0m\]'
  local nl="\n" branch="" status="" mark

  [[ -n "$__xlin_first_prompt" ]] && nl="" && __xlin_first_prompt=""

  if command -v git >/dev/null 2>&1; then
    branch=$(git symbolic-ref --short -q HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    [[ -n "$branch" ]] && branch=" ${dim}on${rst} ${cyan}${branch}${rst}"
  fi

  mark="${blue}❯${rst}"
  if [[ $ec -ne 0 ]]; then
    status=" ${red}✘ ${ec}${rst}"
    mark="${red}❯${rst}"
  fi

  PS1="${nl}${dim}╭─${rst} ${blue}\w${rst}${branch}${status}\n${dim}╰─${rst}${mark} "
  PS2="${dim}  ·${rst} "
  printf '\e]0;%s\a' "${PWD/#$HOME/\~}"     # window title = current folder
}

__xlin_neutralize
PROMPT_COMMAND=(__xlin_prompt "${PROMPT_COMMAND[@]}")   # ours first, so it sees the real exit status

# ------------------------------------------------------------ welcome card
xlin-banner() {
  local b=$'\e[34m' d=$'\e[90m' r=$'\e[0m' bold=$'\e[1m'
  local W=44 line="" os="Linux" k v mt=0 ma=0 used mem up secs dd hh mm disk theme desk shell_v when pad

  printf -v line '%*s' "$W" ''
  line=${line// /─}

  if [[ -r /etc/os-release ]]; then
    while IFS== read -r k v; do
      [[ $k == PRETTY_NAME ]] && { v=${v//\"/}; os=$v; }
    done </etc/os-release
  fi
  while read -r k v _; do
    case $k in MemTotal:) mt=$v ;; MemAvailable:) ma=$v ;; esac
  done </proc/meminfo
  used=$(((mt - ma) / 1024))
  mem="$((used / 1024)).$(((used % 1024) * 10 / 1024)) / $((mt / 1048576)).$(((mt % 1048576) * 10 / 1048576)) GiB"

  read -r up _ </proc/uptime
  secs=${up%.*}; dd=$((secs / 86400)); hh=$((secs % 86400 / 3600)); mm=$((secs % 3600 / 60))
  up="${mm}m"; ((hh > 0)) && up="${hh}h ${up}"; ((dd > 0)) && up="${dd}d ${up}"

  disk=$(df -h --output=used,size / 2>/dev/null | awk 'NR==2 {print $1 " / " $2}')
  theme=$(cat "$HOME/.config/xlin/state/theme" 2>/dev/null || echo light)
  desk=${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}
  shell_v="bash ${BASH_VERSION%%(*}"
  printf -v when '%(%a %d %b  %I:%M %p)T' -1
  pad=$((W - 2 - 4 - ${#when} - 2))

  __xlin_row() { printf '%s│%s  %s%-9s%s%-31s  %s│%s\n' "$d" "$r" "$d" "$1" "$r" "${2:0:31}" "$d" "$r"; }

  printf '\n'
  printf '%s╭%s╮%s\n' "$d" "$line" "$r"
  printf '%s│%s  %s%sXLIN%s%*s%s%s  %s│%s\n' "$d" "$r" "$b" "$bold" "$r" "$pad" '' "$d" "$when" "$d" "$r"
  printf '%s├%s┤%s\n' "$d" "$line" "$r"
  __xlin_row user    "${USER:-$(id -un)}@${HOSTNAME%%.*}"
  __xlin_row system  "$os"
  __xlin_row kernel  "$(uname -r)"
  __xlin_row desktop "$desk"
  __xlin_row shell   "$shell_v"
  __xlin_row uptime  "$up"
  __xlin_row memory  "$mem"
  __xlin_row disk    "${disk:-n/a}"
  __xlin_row theme   "$theme"
  printf '%s╰%s╯%s\n' "$d" "$line" "$r"
}

# Show once per terminal window: a real terminal, no nested shells, not switched off.
if [[ -t 1 && -z "${XLIN_BANNER_SHOWN:-}" && ! -f "$HOME/.config/xlin/state/no-banner" ]]; then
  export XLIN_BANNER_SHOWN=1
  xlin-banner
fi

# ------------------------------------------------------- xlin tab completion
_xlin_complete() {
  local cur=${COMP_WORDS[COMP_CWORD]} cmd=${COMP_WORDS[1]:-} words=""
  if ((COMP_CWORD == 1)); then
    words="help status keys screenshot idle nightlight clipboard notes note version wifi bluetooth bt sound volume brightness battery theme accent welcome wallpaper opacity dock terminal tools power lock session sleep logout poweroff reboot launcher settings panel files pin unpin toggle start restart reload doctor uninstall adapt"
  else
    case $cmd in
      wifi)       words="status list connect disconnect forget on off ip help" ;;
      bluetooth|bt) words="status list scan pair connect disconnect remove on off help" ;;
      sound|volume) words="get set up down mute unmute toggle outputs help" ;;
      brightness) words="get set up down help" ;;
      battery)    words="status mode help"; [[ ${COMP_WORDS[2]:-} == mode ]] && words="saver balanced performance" ;;
      theme)      words="light dark toggle" ;;
      accent)     words="blue teal green rose orange graphite reset" ;;
      wallpaper)  words="next" ;;
      dock)       words="check restart autohide" ;;
      terminal)   words="font banner" ;;
      tools)      words="calculator calendar notes" ;;
      screenshot) words="region full window" ;;
      idle)       words="on off status set" ;;
      nightlight|night) words="on off 3500 4000 4500" ;;
      toggle)     words="wifi bluetooth airplane" ;;
      notes)      words="list dir" ;;
      files)      words="default" ;;
      help)       words="wifi bluetooth sound brightness battery theme" ;;
      settings)   words="wifi bluetooth display sound appearance about" ;;
    esac
    [[ $cmd == dock && ${COMP_WORDS[2]:-} == autohide ]] && words="on off"
    [[ $cmd == terminal && ${COMP_WORDS[2]:-} == banner ]] && words="on off"
  fi
  COMPREPLY=($(compgen -W "$words" -- "$cur"))
}
complete -F _xlin_complete xlin
