# MRtrix3 installation on OSX via homebrew

This homebrew formula is an easy way of installing MRtrix3 on OSX. Please visit the [official website for MRtrix](http://www.mrtrix.org) to access the [documentation for MRtrix3](http://mrtrix.readthedocs.org/), including dependencies and detailed installation instructions. 

If you do not have homebrew yet, install it with 

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

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
