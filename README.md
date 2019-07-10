`rbenv-lock` - An `rbenv` Plugin
==============================================================================

Lock executables to run in a specific Ruby version, with an optional gemset via
`rbenv-gemset`, allowing consistent execution and complete isolation of commands
on the Ruby of your choice.

Built in top of [rbenv][] as a plugin.

[rbenv]: https://github.com/rbenv/rbenv

Written in the [Crystal][] language, meaning it produces binary executables,
though from my understanding the binaries are *not* static compiled, and this 
feature is not available on my platform of choice (macOS). At this time it's 
unclear what dependencies must be present on the system when using a pre-built
binary, but I assume the Crystal runtime must be present.

[Crystal]: https://crystal-lang.org/

******************************************************************************


Status
==============================================================================

rbenv-lock is in a very early stage of development, and production releases have
not yet been made available. It has only been tested on macOS, since those are 
the only workstations I'm running at the moment.

That said, I've been using it successfully for months now.

******************************************************************************


Installation
==============================================================================

Instructions are for macOS **only**, but I don't see any reason the plugin
shouldn't work on other unix-like systems. If you do get 'er running on
something else, please do the right thing and PR your instructions and any
source changes!

Production releases are not yet available, so you need to build from source.

1.  Make sure you have installed, working and in your path:
    1.  rbenv
        
        I install this using Homebrew:
        
            brew install rbenv
        
    2.  rbenv-gemset - if you want to use the gemsets features.
        
        This is available via Homebrew, but I use my own sped-up fork from
        
        https://github.com/nrser/rbenv-gemset
        
    3.  Crystal language (compiler, etc.)
        
        I install this using Homebrew with:
        
            brew install crystal
        
2.  Clone the repo to your rbenv plugins directory
    
    ```bash
    mkdir -p "$(rbenv root)/plugins)"
    cd "$(rbenv root)/plugins"
    git clone https://github.com/nrser/rbenv-lock.git
    cd rbenv-lock
    ```
    
3.  Build the plugin executables
    
    ```bash
    # (in the $(rbenv root)/plugins/rbenv-lock directory)
    make release
    ```
    
    This should produce the following executables
    (in `$(rbenv root)/plugins/rbenv-lock`):
    
        bin/rbenv-lock            # User interface
        bin/rbenv-lock-exec-file  # Executable lock exe files use when run
    
4.  rbenv should automatically find the executables, making the rbenv-lock
    interface available at `rbenv lock ...`.
    
    You can test this by running:
    
        rbenv lock help


******************************************************************************


Usage
==============================================================================

Start at

    rbenv lock help

and go from there.

You can get help with each rbenv-lock command via

    rbenv lock help COMMAND
    
like

    rbenv lock help add

The `add` command is probably where you want to start since you don't yet have 
any locks.

******************************************************************************


Development
==============================================================================

Install from the Git repo as listed above and you're ready to go!


Debug Builds
------------------------------------------------------------------------------

The [Crystal][] compiler is a bit *sloooow* at building releases (optimized
builds), so when you be hacking it can be considerably more productive to
compile *debug* versions and play with those.

Create them with

    make debug

and tell rbenv-lock to use the debug versions by exporting

    export RBENV_LOCK_DEBUG=anything

so it's present in the environment when the revenant things (`rbenv` and lock
exe-files) are run.

The first thing the executables do is check for the presence of
`RBENV_LOCK_DEBUG`, and if they see it *and* they are *release* versions then
they flip over to running the `*-debug` version (via an `exec` to seamlessly
replace the process).

> ### 📢 **_Pro Tip_** - Set Default `make` Rule In Your Env ###
> 
> You can export `RBENV_LOCK_MAKE_DEFAULT=RULE_NAME` in your shell to override
> the default rule run when you execute `make` with no arguments. 
> 
> So, if you're building `debug` over and over during development you can
> 
>     export RBENV_LOCK_MAKE_DEFAULT=debug
> 
> then just run `make`. Save you characters!
>

******************************************************************************


License
==============================================================================

BSD. West coast y'all. Ride or die.
