## https://unix.stackexchange.com/questions/103898/how-to-start-tmux-with-attach-if-a-session-exists
# if run as "tmux attach", create a session if one does not already exist new-session -n $HOST

## Info: https://builtin.com/articles/tmux-config

# +r reload config
bind r source-file ~/.tmux.conf \; display "Reloaded!"

# Changing the Default Prefix
unbind C-Space
set -g prefix C-Space
bind C-Space send-prefix

# Mouse Usage
set -g mouse on
#copy mode
set-option -s set-clipboard off

# setw -g mode-keys vi
# bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -selection clipboard -i"
set -g mouse on
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
bind -n WheelDownPane select-pane -t= \; send-keys -M
bind -n C-WheelUpPane select-pane -t= \; copy-mode -e \; send-keys -M
bind -T copy-mode-vi    C-WheelUpPane   send-keys -X halfpage-up
bind -T copy-mode-vi    C-WheelDownPane send-keys -X halfpage-down
bind -T copy-mode-emacs C-WheelUpPane   send-keys -X halfpage-up
bind -T copy-mode-emacs C-WheelDownPane send-keys -X halfpage-down

# To copy, left click and drag to highlight text in yellow,
# once you release left click yellow text will disappear and will automatically be available in clibboard
# # Use vim keybindings in copy mode
setw -g mode-keys vi
# Update default binding of `Enter` to also use copy-pipe
unbind -T copy-mode-vi Enter
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -selection c"
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"

# Increase History
set-option -g history-limit 10000

# Jump to a Marked Pane
# Prefix + m
bind \` switch-client -t'{marked}'

# Numbering Windows and Panes
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# More Intuitive Split Commands
bind | split-window -hc "#{pane_current_path}"
bind - split-window -vc "#{pane_current_path}"
bind-key "|" split-window -h -c "#{pane_current_path}"
bind-key "\\" split-window -fh -c "#{pane_current_path}"
bind-key "-" split-window -v -c "#{pane_current_path}"
bind-key "_" split-window -fv -c "#{pane_current_path}"

# Swapping Windows
bind -r "<" swap-window -d -t -1
bind -r ">" swap-window -d -t +1

# Keeping Current Path
bind c new-window -c "#{pane_current_path}"

# Toggling Windows and Sessions
bind Space last-window
bind-key C-Space switch-client -l

# Resizing
bind -r C-j resize-pane -D 15
bind -r C-k resize-pane -U 15
bind -r C-h resize-pane -L 15
bind -r C-l resize-pane -R 15

# Breaking and Joining Panes
bind j choose-window 'join-pane -h -s "%%"'
bind J choose-window 'join-pane -s "%%"'


## https://web.archive.org/web/20140109014333/http://blog.e-thang.net/2012/08/14/tmux-and-bash-tab-completion/
# Tab autocompletion (issue)
unbind -n Tab
