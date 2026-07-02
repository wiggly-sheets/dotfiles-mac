# The starting index to use for the command-alias option, used for macros
# (required). This value must be at least 200
command_alias_start_index: 200
# The keybindings that open the action menu (required)
keybindings:
  prefix_table: Space # The keybinding for the prefix key table (required)
  root_table: C-Space # The keybinding for the root key table (optional)
# The menu title config (optional)
title:
  style: align=centre,bold # The title style
  prefix: tmux # A prefix added to every menu title
  prefix_style: fg=green,align=centre,bold # The prefix style
# The menu position (optional)
position:
  x: R
  y: P
# tmux-only environment variables that can be used in commands and macros
# (optional)
custom_variables:
  my_var: my_value
# User-defined macros that can be triggered by the menu (optional)
macros:
  restart-pane: # The macro name
    # The macro commands
    - "respawnp -k -c #{pane_current_path}"
    - display "#{log_info} Pane restarted"
# The root menu items (required)
items:
  - name: Next pane
    key: space # The key that triggers this action
    command: next-pane # A command to run
  - name: Respawn pane
    key: R
    macro: restart-pane # A custom macro (defined above)
  - separator: true # A menu separator
  - name: +Layout # A submenu
    key: l
    menu: # The submenu items
      - name: Next
        key: l
        command: nextl
        transient: true # Whether to keep the menu open until ESC is pressed
