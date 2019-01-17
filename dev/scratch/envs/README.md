About Them Environment Variables
==============================================================================

The stuff in this directory is me trying to work out the environment, which is
pretty much *all* of the complexity.


Variables I Know
------------------------------------------------------------------------------

And the little I know about them.

### rbenv

As listed here: <https://github.com/rbenv/rbenv#environment-variables>
    
1.  `RBENV_VERSION` - one of `rbenv versions` to use, overrides all else.
    
    A trace of sorts of how this seems to be handled:
    
    1.  Gets **SET** and **EXPORTED** in `rbenv-exec` to the output of
        `rbenv-version-name`.
    2.  In `rbenv-version-name`:
        1.  If `RBENV_VERSION` **IS NOT** set:
            1.  Tries to find a version file with `rbenv-version-file`, which
                will walk up from the current dir looking for a `.ruby-version`,
                and if it doesn't find one, return `$RBENV_ROOT/version`, which
                is the global version (as `rbenv global` returns).
                
                So, this should always find a file, unless maybe the `global`
                was never set?
                
            2.  Reads that file into `RBENV_VERSION`, defaulting to '' if 
                something goes wrong (like the file not being there?).
                
            3.  Goes through hooks for `version-name`, which I'm not going to
                fuck with right now.
                
            4.  If it still doesn't have anything in `RBENV_VERSION`, it uses
                `system`.
                
            All pretty damn reasonable logically, though God I hate reading
            Bash scripts.
    
    What's important to note is that since all shims go through `rbenv exec`
    they will *always* have `RBENV_VERSION` set, and so will their children 
    unless the `ENV` is modified in some way.
    
    At first I thought that this was how child processes would end up in the
    correct Ruby version, but then I remembered that rbenv *also* prepends
    the Ruby version's `bin` directory to the `PATH`, so those executables
    will be found first in most cases.
    
    However, this does matter when using the `system` version, since it's at
    `/usr/bin/ruby`, and rbenv does not stick `/usr/bin` on the front of `PATH`,
    since that would fuck all sorts of shit up. Therefor, in this case, child
    processes will find the shim, and `RBENV_VERSION` is what will get them 
    back to the `system` version instead of defaulting to the global one.
    
    Sticking the version `bin` dir on the front of `PATH` seems like it could
    result in some weirdness, but I'll discuss that when in the `PATH` section.
    And it's not like weirdness is unheard of using rbenv, though it's nice to 
    start to understand it a bit more.
    
2.  `RBENV_ROOT` - where versions and shims and such are, defaults to
    `~/.rbenv`. 
    
    `RBENV_ROOT` gets **SET** and **EXPORTED** in `rbenv`. If it has a trailing
    slash it's removed.



1.  `PATH` - we all know this dude. However, rbenv fucks with it, and that's
    something we need to take account of.

