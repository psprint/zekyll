## Quick Start

Create a file ~/.zekyllfile:

```zsh
yes
user psprint
zkl vega_sirius_software_zsh_linux_z3kyll
emit
```

run `~/zekyll`, and have your .zshrc generated (`~/.zshrc_new` to be exact). From what? Files taken from `psprint/zkl` Github repository:
- file "ve"
- file "ga"
- etc.

What's the point? Sharing. Easy introduction of snippet from other user:

```
yes
zkl psprint:vega_sirius_software
zkl someone:ab
zkl psprint:zsh_linux_z3kyll
emit
```

Other point? On new machine, one has to do only two steps. Install zekyll with:

```zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/psprint/zekyll/master/install.sh)"
```

And then create ~/.zekyllfile with an easy to type phrase. Maybe even easy to
remember, for sure easy to carry in wallet written on a paper.

Zekyll works with any dotfile. Here are advantages of static page generation
(with Jekyll like software) deceptively translated to dotfile word:

### No backend

Dotfiles are often "backends", they're not used directly. Yes, one can have
dotfiles commited to Github, but on each installation changes are rather
introduced.

### No moving parts

When sharing dotfiles, it's a situation when one has to track down desired
snippet in someone's large dotfile, adapt it and store. Here it will be
different. The snippets will be broadly available. If someone will decide to
share a snippet that binds key `Ctrl-t`, he can easily choose to provide
version that binds key `Ctrl-F`. Let's share snippet under name ab, then ac,
who cares.  So you will be able to directly incorporate someone's carefully
prepared for share dotfile's snippet. Statically.

## IRC Channel

Channel `#zplugin@freenode` is a support place for all author's projects. Connect to:
[chat.freenode.net:6697](ircs://chat.freenode.net:6697/%23zplugin) (SSL) or [chat.freenode.net:6667](irc://chat.freenode.net:6667/%23zplugin)
 and join #zplugin.

Following is a quick access via Webchat [![IRC](https://kiwiirc.com/buttons/chat.freenode.net/zplugin.png)](https://kiwiirc.com/client/chat.freenode.net:+6697/#zplugin)
