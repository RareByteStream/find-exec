# find-exec

Utility to find the first valid absolute path of 
a named executable file/symlink from specified 
directory paths.

Written with bash, primarily for bash.

[Interface](https://github.com/RareByteStream/find-exec/blob/main/INTERFACE.md)
page is recommended for understanding out how to use and understand the utility.





## Repository Installation

From [`github`](https://github.com/RareByteStream/find-exec):

```bash
git clone https://github.com/RareByteStream/find-exec.git
cd find-exec
```




## Testing

```bash
./test 
```
Runs the dependency check, runs the tests and prints their results.
Piping to a pager is recommended. 
But carriage returns have to be removed in between.
Eg. `./test | sed 's/\r//g' | less`.





## System Installation

```bash
./install -rc
./install --home
```
Installs it to user's home.
Edits the .bashrc for startup sourcing.


```bash
./install -s
./install --system
```
Installs it to first viable path in $PATH,
making sure its not an sbin directory.


```bash
./install -a
./install --all
```
Does both of the above.


```bash
./install -c=/target/dir
./install --custom=/target/dir
```
Installs it to given directory path
irregardless of its existence in `$PATH`.





## Collaboration

Pull requests are welcome but they would be regarded 
as friendly recommendations. It's recommended to use 
[issues](https://github.com/RareByteStream/find-exec/issues) 
page instead.

[Issues](https://github.com/RareByteStream/find-exec/issues)
page is recommended for requesting new features, 
reporting bugs, reporting shortcomings for edge cases etc.




## Licensing

find-exec is open source software released under
[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).


