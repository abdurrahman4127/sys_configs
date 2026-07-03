source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
    # smth smth
#end

# ----------------- from ParrotOS
# Aliases
alias ll='ls -lh'
alias la='ls -lha'
alias please='sudo'
alias fucking='sudo'
alias x='exit'
alias push='git push origin main'
alias w='whereis'
alias sdn='poweroff'
alias zzz='poweroff'
alias ff='fastfetch'
alias cpy='xclip -selection clipboard'
alias gpu='__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia '
# -----------------

# --------- to compress pdf
alias compress_pdf='gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dBATCH -sOutputFile='


# Misc
alias ..='cd ..'
alias ...='cd ../..'

# Package management
alias install='sudo pacman -S'
alias reinstall='sudo pacman -S --overwrite "*"'
alias uu='shelly sync && shelly upgrade && cachy-update'
alias cc='sudo pacman -Sc'

# Git
alias push='git push origin main'


# ----------- customized fish prompt
function fish_prompt
    set -l last_status $status
    set -l duration ""
    if test $CMD_DURATION -gt 1000
        set duration (math -s0 $CMD_DURATION / 1000)"s"
    end
    
    # top line
    set_color normal
    echo -n "╭─ "
    if test (id -u) -eq 0
        set_color red
        echo -n "root"
    else
        set_color green
        echo -n (whoami)
    end
    set_color brblack
    echo -n " ["
    set_color cyan
    echo -n (pwd | sed "s|$HOME|~|")
    set_color brblack
    echo -n "]"
    
    # git branch
    set -l git_branch (fish_git_prompt "%s" 2>/dev/null)
    if test -n "$git_branch"
        set_color brblack
        echo -n " ("
        set_color magenta
        echo -n "⎇ :$git_branch"
        set_color brblack
        echo -n ")"
    end
    
    if test $last_status -ne 0
        set_color red
        echo -n " ✗"
    end
    if test -n "$duration"
        set_color yellow
        echo -n " 󱎫:$duration"
    end
    echo ""
    
    # bottom line
    set_color normal
    echo -n "╰───"
    set_color --bold normal
    echo -n "❯ "
    set_color normal
end
