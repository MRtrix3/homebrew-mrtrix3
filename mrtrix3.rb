  class Qt5Requirement < Requirement
  fatal true
  satisfy :build_env => false do
    if File.file?("#{HOMEBREW_PREFIX}/opt/qt5/bin/qmake")
      @qmake = which("#{HOMEBREW_PREFIX}/opt/qt5/bin/qmake")
    else
      @qmake = which('qmake')
    end
    @qmake
  end

  env do
    ENV.append_path 'PATH', @qmake.parent
  end

  def message
    message = <<-EOS.undent
      Homebrew was unable to find an installation of Qt 5. You can install it for instance via homebrew:


      brew update
      brew install qt5


    EOS
  end
end



class Mrtrix3 < Formula
  desc "MRtrix provides a set of tools to perform diffusion-weighted MRI white matter tractography
    in the presence of crossing fibres, using Constrained Spherical Deconvolution, and a
    probabilisitic streamlines algorithm. These applications have been written from scratch in
    C++, using the functionality provided by Eigen, and Qt.

    The software is currently capable of handling DICOM, NIfTI and AnalyseAVW image formats, amongst
    others. The source code is distributed under the Mozilla Public License.

    For more information on how to install and use MRtrix go to mrtrix.org or http://mrtrix.readthedocs.io
    "

  homepage "mrtrix.org"

  head "https://github.com/MRtrix3/mrtrix3.git"

  url "https://github.com/MRtrix3/mrtrix3.git"

  version  '0.3.15-451-gaf34ff8'
revision 0

  # devel do
  #   url 'https://github.com/MRtrix3/mrtrix3.git', :branch => 'master', :revision => 'bogus474279845b7e79fc2b5ffad'
  #   version '0.3_dev'
  # end

  # depends_on :python if MacOS.version <= :snow_leopard
  depends_on :python => :recommended
  depends_on "eigen" => :build
  depends_on "pkg-config" => :build
  # depends_on "qt5" # not used as users might want to use an existing qt or install mrtrix without a GUI
  depends_on Qt5Requirement => :recommended

  option "build_single_thread", "This is useful if your computer has many cores but not enough RAM to build MRtrix using multiple threads."
  option "stable", "Install latest tagged stable version. Default is last commit on master branch."
  option "without-matlab", "Do not add MRtrix scripts to matlab path."

  def execute (cmd)
    # verbose alternative to: system cmd
    require 'pty'
    raw = ''
    PTY.spawn(cmd) do |stdout_err, stdin, pid|
      begin
        while (char = stdout_err.getc)
          raw << char
          print char
        end
      rescue Errno::EIO # always raised when PTY runs out of input
      ensure
        Process.waitpid pid # Wait for PTY to complete before continuing
      end
    end
    return raw
  end

  def set_matlab_path ()
    matlab_add = <<-EOS.undent
        import os, glob, sys

        def path_is_set(startup):
            if not os.path.isfile(startup):
                return False
            with open (startup, "r") as inp:
                for line in inp:
                    if "/usr/local/opt/mrtrix3/matlab" in line:
                        return True
            return False

        matlab_bins = glob.glob("/Applications/MATLAB_R20*/bin/matlab")
        if not len(matlab_bins):
            print ("warning: no matlab binary found")
            sys.exit(0)

        for bin in matlab_bins:
            matlab_root = os.path.split(os.path.split(bin)[0])[0]
            startup = os.path.join(matlab_root, "toolbox", "local", "startup.m")
            if not path_is_set(startup):
                with open (startup, "a") as inp:
                    inp.write("addpath('#{prefix}/matlab')" + os.linesep )
                print ("added mrtrix path to " + startup)
            else:
                print ("mrtrix path already set in " + startup)
      EOS
      open('matlab_add.py', 'w') do |f|
        f.puts matlab_add
      end
      system "python", "matlab_add.py"
  end

  def install
    xcodeerror=`xcodebuild 2>&1`
    puts xcodeerror
    if xcodeerror.include? "tool 'xcodebuild' requires Xcode"
      puts "\nxcodebuild failed with the error message:"
      puts xcodeerror 
      puts "If the command line tools were installed before Xcode, you can fix this with:"
      puts "sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
      raise 'command line tools failure'  
    end

    if build.include? "stable"
      system "git", "reset",  "--hard", "origin/master"
      latesttag = `git describe --tags --abbrev=0`.strip
      system "git", "checkout", "#{latesttag}"
    end

    cp "LICENCE.txt", "#{prefix}/"
    bin.mkpath()
    system "mkdir", "#{prefix}/lib"
    system "mkdir", "#{prefix}/release"
    system "ln", "-s", "#{prefix}/bin", "#{prefix}/release/bin"

    system "mkdir", "#{prefix}/matlab"
    cp_r 'matlab/.', "#{prefix}/matlab/"
    # add mrtrix to matlab path
    if not build.include? "without-matlab"
      set_matlab_path()
    end

    system "mkdir", "#{prefix}/icons"
    cp_r 'icons/.', "#{prefix}/icons/"

    if build.include? "build_single_thread"
      ENV["NUMBER_OF_PROCESSORS"] = "1"
    end

    system "git", "log", "-1"
    system "python", "--version"
    conf = [ "./configure"]
    if build.include? "without-qt5"
      conf.push("-nogui")
    end
    execute (conf.join(" "))

    execute ("./build")

    bin.install Dir["release/bin/*"]
    cp_r 'release/lib/.', "#{prefix}/lib/"

    # copy and link scripts
    system "mkdir", "#{prefix}/scripts"
    cp_r 'scripts/.', "#{prefix}/scripts/"
    # find scripts that have lib.app.initParser and add others manually
    scripts = `find "#{prefix}/scripts" -type f -print0 | xargs -0 grep -l "lib.app.initialise"`
    scripts = scripts.split("\n")
    other_scripts = ["#{prefix}/scripts/foreach", \
      "#{prefix}/scripts/average_response", \
      "#{prefix}/scripts/blend", \
      "#{prefix}/scripts/convert_bruker", \
      "#{prefix}/scripts/notfound"]
    scripts.concat other_scripts
    scripts = scripts.uniq.sort
    for scrpt in scripts
      print "linking "+Pathname(scrpt).each_filename.to_a[-1]+"\n"
      # bin.install_symlink prefix/"scripts/"Pathname(scrpt).each_filename.to_a[-1]
      system "ln", "-s", scrpt, "#{prefix}/bin/"+Pathname(scrpt).each_filename.to_a[-1]
    end

    # TODO: mrtrix_bash_completion
    # TODO: tests, see https://github.com/optimizers/homebrew-fenics/blob/master/ffc.rb
    print "Installation done. You can find MRtrix in #{prefix}\n"

  end
end

