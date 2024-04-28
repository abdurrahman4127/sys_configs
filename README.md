it is supposed to look like this:
┌─[ar@jarvis]─[~]
└──╼ $

but now it looks like this:
ar@jarvis:~$

# for terminal view
PS1=
"
\[\033[0;31m\]┌─[
\[\033[0;32m\]\u
\[\033[0;93m\]@
\[\033[0;36m\]\h
\[\033[0;31m\]][
\[\033[0;90m\]\w
\[\033[0;31m\]]
\n
\[\033[0;31m\]└──╼ 
\[\033[0;93m\]$
\[\033[0m\]
"
