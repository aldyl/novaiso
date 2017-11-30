# novaiso
Create  a new clean filesystem into a Live Cd installable, with support uefi an legacy boot using grub2 and isolinux.

Project Title

Nova ISO for working with Live CD.


Getting Started

This scripts and utilities make easy the life of the developers who work with Live CD creation scripts.


Prerequisites

Before using this scripts make sure that this packages are installed in your system.

1. debootstrap
2. 
3. 
4. 
5. 

Installing

To start using this tools just clone this repository:

$ git clone git@/novaiso.git


Make all the executables accesible for bash, without the extension. For example:

$ mkdir ~/bin
$ ln -sfv /path/to/the/cloned/project/novaiso.sh ~/bin/novaiso

Usage

This script use configure file located in project folder ./novaisorc

For example:

$ novaiso [ARGS]

For help with the available commands execute:

$ novaiso --help
