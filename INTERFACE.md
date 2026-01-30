
# Irregular Mode Arguments

Below arguments are irregular mode flags. 
They are only valid if they are given as the first argument 
and they will skip the parsing of the rest of the arguments 
along with any other execution after the mode selection phase,
through an early exit.

Exit code `255` is reserved for informational/interactive modes 
that cause an early exit and must not be interpreted as success or failure.

- `--usage`/`--usages`: Prints patterns of usage modes mentioned here. Early exits with `255`.

- `--help`: Prints invocation manual with program name, version, 
brief description of what usage is it intended for 
and patterns of usage modes at top. Early exits with `255`.

- `--deps`/`--dependencies`: Checks the system wide availablity of 
each non-bash command and prints their availability status.
Early exits with; `0` if all dependencies are found, 
`1` if at least one of them was not found.

- `--version`: Prints the version and early exits with `255`.




# Regular Mode Arguments


## Usage and Exit Codes

- `NAME <regular-mode-flags>`: If the first argument NAME is not a usage mode flag, 
it will be taken as the executable name. That is the regular mode.
Rest of the arguments will be expected to be regular mode flags which are mentioned below.
Regular mode exits with codes:

   - `0`: Path corresponds to an ordinary file in the filesystem and has execution permission.
   - `1`: Encountered unusable argument(s) at parsing phase and skipped execution phase due to that.
   - `2`: Couldn't find any type of file in any of the provided paths with execution permission.
   - `3`: Found an entry in file-system but it was not an ordinary file.



## Path Flags

Paths are provided as seperated by `:` 
and merged into the flag with `=`.
Example: `--paths=/usr/bin:/bin:/target/dir`.


- `--paths=PATHS`: Provides the main list of paths to search in.
If PATHS is not provided or empty it will be copied from $PATH.

- `--prepends=PATHS`: Adds the given paths at the beggining of the main list.

- `--appends=PATHS`: Adds the given paths at the end of the main list.



## Search Behavior Flags

- `--max-follows=N`: Limits the maximum amount of links followed to `N`,
when the found executable is a symlink, effectively returning 
the path resolved from the last link.
Has to be a valid integer expression.
Cannot be less than 0, default value is 100.

- `--physical`/`-P`: Transforms the result to not contain any `.`, `..`
components and any component that doesn't correspond 
to a named non-link parent directory entry.

- `--canonical`/`-C`: Transforms the result to not contain any `.`, `..`
components. Doesn't resolve parent directory links to their targets.
Has no effect if `--physical` is provided.




## Interface Behavior Flags

- `--silent`/`-s`: Cancels the error reporting phase. 
Errors will still be checked and error lines will 
be stored but they will not be sent to stderr.

- `--interactive`/`-i`: The result path that is sent to stdout 
will be wrapped with `'` and terminated by `\n\r` at the end, 
to make it readable in terminal.

- `--no-stdout`/`-O`: Result will not get sent to stdout.
Has no effect if `--interactive` is provided.


**WARNING**: If the exec-find is invoked as a subprocess via `exec-find.sh`, 
below interfaces will silently fail because a seperate bash process 
will be spawned which have their own names and values (variables).
It is recommended to use `. find-exec.sh` or `source find-exec.sh` 
and then invoke the imported function via `find-exec` to be able to leverage them.


- `--declare-name=KEY`: Declares or assigns the result path to KEY regarded as the name.
If `--declare-name`, `--declare-name=""` or `-d` is supplied, 
KEY is set as the default KEY, which is `_found_exec_`. 
If the name KEY exists in caller scope or any of the parent scopes
as a name declared using `local`, result will be assigned to 
the innermost name in it's own scope.
To declare it as a global variable one must supply the KEY 
as a name that is not in the local scope of any of the callers at outer scopes.


