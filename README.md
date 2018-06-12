master: [![Run Status](https://api.shippable.com/projects/5ac50b3494f2af07000852d9/badge?branch=master)](https://app.shippable.com/github/alire-project/alr)
testing: [![Run Status](https://api.shippable.com/projects/5ac50b3494f2af07000852d9/badge?branch=testing)](https://app.shippable.com/github/alire-project/alr)

# ALR #

ALIRE: Ada LIbrary REpository.

A catalog of ready-to-use Ada libraries plus a command-line tool (`alr`) to obtain, compile, and incorporate them into your own projects. It aims to fulfill a similar role to Rust's `cargo` or OCaml's `opam`.

### Caveat emptor ###

Documentation at this time is minimal. Expect further efforts in this direction until this warning is removed.

## TL;DR ##

To see available projects per platform/compiler, see the [status folder](status)

Available for Debian testing / Ubuntu >=17.10

To install run the following as user in a terminal, or see below for more details.

    curl https://raw.githubusercontent.com/alire-project/alr/master/install/alr-bootstrap.sh -o ./alr-bootstrap.sh && bash ./alr-bootstrap.sh && rm -f ./alr-bootstrap.sh || echo Installation failed

## Design principles ##

alr is tailored to userspace, in a similar way to Python's virtualenv. A project or workspace will contain all its dependencies.

At this time some projects require platform packages. In this case the user will be asked to authorize a `sudo` installation through the platform package manager.

Dependencies of a project are managed through an Ada specification file that must be compiled with `alr`. `alr` generates an initial file for the user that can be modified to reflect the project dependencies. 

The complete build environment is set up with another file generated by `alr` for every project: a GNAT aggregate project that specifies the paths of necessary dependencies, thus freeing the user from concerns about installation paths. The user simply adds the used projects to its own project GPR file with their simple name.

## Supported platforms ##
Alire requires a recent Ada 2012 compiler. In practice, this currently means GNAT GPL 2017 or GNAT FSF 7.2 onward. In other words, Debian testing or Ubuntu 17.10+.

Alire is known _not_ to work in current Debian 9 stable or any earlier versions of Ubuntu stock compilers.

Note that, for projects that require platform-provided Ada libraries (such as Debian's GtkAda), the platform compiler will be used automatically, so even having GPL 2017 in older platforms some projects may be unavailable due to missing dependencies.

## Installation ##
Copy, paste and execute in a terminal as a regular user the following command:

    curl https://raw.githubusercontent.com/alire-project/alr/master/install/alr-bootstrap.sh -o ./alr-bootstrap.sh && bash ./alr-bootstrap.sh && rm -f ./alr-bootstrap.sh || echo Installation failed

Or, alternatively, clone the repository and launch the installation script:

1. `git clone --recursive https://github.com/alire-project/alr.git`
2. `cd alr`
3. `bash install/alr-bootstrap.sh`
    
## First steps ##
The following miniguide shows how to obtain and compile already packaged projects, and create your own. First, create or enter into some folder where you don't mind that new project folders are created by the `alr` tool

Run `alr` without arguments to get a summary of available commands.

Run `alr --help` for global options about verbosity.

Run `alr help <command>` for more details about a command.

### Downloading, compiling and running an executable project ###
Obtaining an executable project already cataloged in Alire is straightforward. We'll demonstrate it with the `hello` project which is a plain "Hello, world!" application (or you can use the `hangman` or `eagle_lander` projects as funnier alternatives).

Follow these steps:

1. Issue `alr get hello`
2. Enter the new folder you'll find under your current directory: `cd hello*`
3. Build and run the project with `alr run`. This will compile and then launch the resulting executable.

As a shorthand, you can use `alr get --compile hello` to get and compile the program in one step.

### Creating a new project ###
Alire allows you to initialize an empty GNAT binary or library project with ease:

1. Issue `alr init --bin myproj` (you can use --lib for a library project).
2. Enter the folder: `cd myproj`
3. Check that it builds: `alr compile`
4. Run it: `alr run`

## Dependencies and upgrading ##
Alire keeps track of a project dependencies by compiling the file `./alire/alr_deps.ads` file of your project. You may check the one just created in the previous example.

This file can be managed through `alr`:

* `alr with project_name` adds a dependency. You can immediately 'with' its packages in your code.
* `alr with --del project_name` removes a dependency.
* `alr with --from yourproject.gpr` reads the given GPR file and adds dependencies specified in comments as alr invocations. For example:

    ```Ada
    with "xstrings"; -- alr with xstrings
    project My_Project is
    ```

Alternatively you can edit the file (example in the works) and then issue one of:

* `alr update`, which will fetch any additional dependencies in your project; or
* `alr update --online`, which will previously update the Alire catalog to obtain newly available releases.

As a shorthand, you can also use `alr build` to both update and compile in a single command.

## Finding available projects ##
For quick listing of projects and its description you can use the `list` command:

* `alr list [substring]`

There's also a search command which provides more details:

* `alr search <substring>` will look for `substring` in project names.
* `alr search --list` will list the whole catalog.

Even more details are obtained with:

* `alr show <project>`

This last command will show generic information. To see the one that specifically applies to your platform:

* `alr show --native <project>`

Also, adding `--private` will show further details irrelevant to users of the library, but important to `alr` packaging, if any.

## Troubleshooting ##

By default `alr` is quite terse and will hide the output of subprocesses, mostly reporting only success or failure. If you hit any problem, increasing verbosity (-v or even -d) is usually enough to get an idea of the root of the problem.

## Further reading ##

More comprehensive documentation is forthcoming, so stay tuned! Meanwhile, you can check the [draft paper](https://github.com/alire-project/alr/blob/master/doc/2018-03.alr-draft.pdf) in the `doc` folder for more details about `alr` internals, or inspect [index files](https://github.com/alire-project/alire/tree/master/index) to get an idea of how projects are included into the catalog.
