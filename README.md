# debtocp

debtocp is a script to convert a debian package into an IGEL OS custom partition.  

### Usage

Usage: debtocp.sh [OPTIONS] Package.deb
OPTIONS include:
-i file         :Script file to be added and called by default CP init
-d directory    :Directory of files to be added to CP

The -i argument is a script that you want to call immediately after the default CP initialization.  Note that there is already code included in the default CP initialization to create links in the normal filesystem locations out to your custom partition mount point.  Your extra CP intialization code runs after the default init on installation and after every reboot of IGEL OS.

The -d argument is a directory that contains other files/directories that you want to include at the root of the CP.

Running this command creates a directory in your current working directory named results-<package name>.  Inside this directory, you'll find the tar.bz2 and inf files that you can distribute out to IGEL OS.

License
----

MIT
