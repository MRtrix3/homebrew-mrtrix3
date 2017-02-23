# MRtrix3 installation on macOS via homebrew

This homebrew formula is an easy way of installing MRtrix3 on macOS. Please visit the [official website for MRtrix](http://www.mrtrix.org) to access the [documentation for MRtrix3](http://mrtrix.readthedocs.org/), including dependencies and detailed installation instructions. 

If you do not have homebrew yet, install it with (you might need to install Xcode first, see Troubleshooting section):

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    
    brew doctor

Continue if you get `Your system is ready to brew`.

You need to add the MRtrix3 tap to homebrew

    brew tap MRtrix3/mrtrix3

## Using the latest version of MRtrix3

You can install the latest version of MRtrix3 with:

    brew install mrtrix3
    
You can get all installation options with

    brew info mrtrix3
    
## Using the latest stable version of MRtrix3

You can install the latest tagged (stable) version of MRtrix3 with:

    brew install mrtrix3 --stable
    
##  Updating MRtrix3

MRtrix3 will get upgraded when you upgrade all homebrew packages:

    brew update
    brew upgrade
    
If you want to avoid upgrading MRtrix3 the next time you upgrade homebrew you can do so with

    brew pin mrtrix3
    
## Troubleshooting

Is Xcode installed? `xcode-select -p` shoud give you `/Applications/Xcode.app/Contents/Developer`. If not: run `xcode-select --install` and complete the setup. 

Xcode up to date? run `softwareupdate --install --all`

Check if Xcode command line tools are installed: `xcode-select -p` should give you `/Library/Developer/CommandLineTools`

If you run out of memory during installation of MRtrix3, use the option `--without-multithreaded_build`

If you get permission errors try `cd /usr/local && sudo chown -R $(whoami) bin etc include lib sbin share var Frameworks`

Troubleshoot your homebrew installation (if this does not help, [this](https://github.com/Homebrew/brew/blob/master/docs/Common-Issues.md) might help):

    softwareupdate --install --all
    brew update
    brew update
    brew upgrade
    brew doctor # follow the instructions

You can test your MRtrix3 installation with

    brew test -d mrtrix3
    
