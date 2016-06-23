# MRtrix3 installation on OSX via homebrew

If you do not have homebrew yet, install it as described in http://brew.sh/. 

You need to add the MRtrix3 tap to homebrew

    brew tap MRtrix3/mrtrix3

## Using the latest verions of MRtrix3

You can install the latest version of MTrix with:

    brew install --HEAD mrtrix3
    
Homebrew will not update MRtrix3 automatically. To update mrtrix to the latest version use 

    brew reinstall --HEAD  mrtrix3

## Using the latest stable (tagged) version of MRtrix3  

You can install the latest tagged stable version of MRtrix3 with

    brew install mrtrix3
    
Homebrew will upgrade MRtrix3 if there is a new tagged version when you upgrade your homebrew packages. You can do that manually with

    brew update
    brew upgrade mrtrix3
