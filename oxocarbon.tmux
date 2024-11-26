#!/usr/bin/env bash
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_tmux_option() {
  local option value default
  option="$1"
  default="$2"
  value="$(tmux show-option -gqv "$option")"

  if [ -n "$value" ]; then
    echo "$value"
  else
    echo "$default"
  fi
}

set() {
  local option=$1
  local value=$2
  tmux_commands+=(set-option -gq "$option" "$value" ";")
}

setw() {
  local option=$1
  local value=$2
  tmux_commands+=(set-window-option -gq "$option" "$value" ";")
}

main() {
  local mode="$(get_tmux_option "@oxocarbon_mode" "dark")"

  # Aggregate all commands in one array
  local tmux_command=()

  source /dev/stdin <<<"$(sed -e "/^[^#].*=/s/^/local /" "${PLUGIN_DIR}/oxocarbon-${mode}.tmuxtheme")"

  # status
  set status "on"
  set status-bg "${base00}"
  set status-justify "left"
  set status-left-length "100"
  set status-right-length "100"

  # messages
  set message-style "fg=${base08},bg=${base03},align=centre"
  set message-command-style "fg=${base08},bg=${base03},align=centre"

  # panes
  set pane-border-style "fg=${base03}"
  set pane-active-border-style "fg=${base0B}"

  # windows
  setw window-status-activity-style "fg=${base06},bg=${base00},none"
  setw window-status-separator ""
  setw window-status-style "fg=${base06},bg=${base00},none"

  # --------=== Statusline

  # NOTE: Checking for the value of @catppuccin_window_tabs_enabled
  local wt_enabled
  wt_enabled="$(get_tmux_option "@oxocarbon_window_tabs_enabled" "off")"
  readonly wt_enabled

  local right_separator
  right_separator="$(get_tmux_option "@oxocarbon_right_separator" "")"
  readonly right_separator

  local left_separator
  left_separator="$(get_tmux_option "@oxocarbon_left_separator" "")"
  readonly left_separator

  local user
  user="$(get_tmux_option "@oxocarbon_user" "off")"
  readonly user

  local host
  host="$(get_tmux_option "@oxocarbon_host" "off")"
  readonly host

  local date_time
  date_time="$(get_tmux_option "@oxocarbon_date_time" "off")"
  readonly date_time

  # These variables are the defaults so that the setw and set calls are easier to parse.
  local show_directory
  readonly show_directory="#[fg=$base0C,bg=$base00,nobold,nounderscore,noitalics]$right_separator#[fg=$base00,bg=$base0C,nobold,nounderscore,noitalics]  #[fg=$base06,bg=$base03] #{b:pane_current_path} #{?client_prefix,#[fg=$base0A]"

  local show_window
  readonly show_window="#[fg=$base0C,bg=$base00,nobold,nounderscore,noitalics]$right_separator#[fg=$base00,bg=$base0C,nobold,nounderscore,noitalics] #[fg=$base06,bg=$base03] #W #{?client_prefix,#[fg=$base0A]"

  local show_session
  readonly show_session="#[fg=$base0D]}#[bg=$base03]$right_separator#{?client_prefix,#[bg=$base0A],#[bg=$base0D]}#[fg=$base00] #[fg=$base06,bg=$base03] #S "

  local show_directory_in_window_status
  #readonly show_directory_in_window_status="#[fg=$base00,bg=$base0B] #I #[fg=$base06,bg=$base03] #{b:pane_current_path} "
  readonly show_directory_in_window_status="#[fg=$base00,bg=$base0B] #I #[fg=$base06,bg=$base03] #W "

  local show_directory_in_window_status_current
  #readonly show_directory_in_window_status_current="#[fg=$base00,bg=$base0G] #I #[fg=$base06,bg=$base00] #{b:pane_current_path} "
  readonly show_directory_in_window_status_current="#[fg=colour232,bg=$base0G] #I #[fg=colour255,bg=colour237] #(echo '#{pane_current_path}' | rev | cut -d'/' -f-2 | rev) "

  local show_window_in_window_status
  readonly show_window_in_window_status="#[fg=$base06,bg=$base00] #W #[fg=$base00,bg=$base0B] #I#[fg=$base0B,bg=$base00]$left_separator#[fg=$base06,bg=$base00,nobold,nounderscore,noitalics] "

  local show_window_in_window_status_current
  readonly show_window_in_window_status_current="#[fg=$base06,bg=$base03] #W #[fg=$base00,bg=$base0G] #I#[fg=$base0G,bg=$base00]$left_separator#[fg=$base06,bg=$base00,nobold,nounderscore,noitalics] "
  #setw -g window-status-current-format "#[fg=colour232,bg=$base0G] #I #[fg=colour255,bg=colour237] #(echo '#{pane_current_path}' | rev | cut -d'/' -f-2 | rev) "


  local show_user
  readonly show_user="#[fg=$base0B,bg=$base03]$right_separator#[fg=$base00,bg=$base0B] #[fg=$base06,bg=$base03] #(whoami) "

  local show_host
  readonly show_host="#[fg=$base0B,bg=$base03]$right_separator#[fg=$base00,bg=$base0B]󰒋 #[fg=$base06,bg=$base03] #H "

  local show_date_time
  readonly show_date_time="#[fg=$base0B,bg=$base03]$right_separator#[fg=$base00,bg=$base0B] #[fg=$base06,bg=$base03] $date_time "

  # Right column 1 by default shows the Window name.
  local right_column1=$show_window

  # Right column 2 by default shows the current Session name.
  local right_column2=$show_session

  # Window status by default shows the current directory basename.
  local window_status_format=$show_directory_in_window_status
  local window_status_current_format=$show_directory_in_window_status_current


  if [[ "${wt_enabled}" == "on" ]]; then
    right_column1=$show_directory
    window_status_format=$show_window_in_window_status
    window_status_current_format=$show_window_in_window_status_current
  fi

  if [[ "${user}" == "on" ]]; then
    right_column2=$right_column2$show_user
  fi

  if [[ "${host}" == "on" ]]; then
    right_column2=$right_column2$show_host
  fi

  if [[ "${date_time}" != "off" ]]; then
    right_column2=$right_column2$show_date_time
  fi

  set status-left ""

  set status-right "${right_column1},${right_column2}"

  setw window-status-format "${window_status_format}"
  setw window-status-current-format "${window_status_current_format}"

  # --------=== Modes
  #
  setw clock-mode-colour "${base0B}"
  setw mode-style "fg=${base0C} bg=${base02} bold"

  tmux "${tmux_commands[@]}"
}

main "$@"
