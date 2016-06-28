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
      Homebrew was unable to find an installation of Qt 5. You can install it manually or with
      brew install qt5
    EOS
  end
end

class Mrtrix3 < Formula
  desc "MRtrix provides a set of tools to perform diffusion-weighted MRI white matter tractography in the presence of crossing fibres, 
    using Constrained Spherical Deconvolution (Tournier et al.. 2004; Tournier et al. 2007), and a probabilisitic streamlines algorithm 
    (Tournier et al., 2012). These applications have been written from scratch in C++, using the functionality provided by Eigen, and Qt. 
    The software is currently capable of handling DICOM, NIfTI and AnalyseAVW image formats, amongst others. The source code is distributed 
    under the Mozilla Public License.

    For more information on how to install and use MRtrix go to http://mrtrix.readthedocs.io
    "
  homepage "mrtrix.org"

  url "https://github.com/MRtrix3/mrtrix3/archive/0.3.15.tar.gz"
  sha256 "abce25cde2870abc8bd487f44f061d3e3bd42f36618519b740b7f5e74eba1e20"
  version "0.3.15"
  head 'https://github.com/MRtrix3/mrtrix3.git'
  revision 1

  depends_on "eigen" => :build
  depends_on "pkg-config" => :build
  # depends_on "qt5" # not used as users might want to use an existing qt or install mrtrix without a GUI
  depends_on Qt5Requirement => :recommended

  option "build_single_thread", "This is useful if your computer has many cores but not enough RAM to build MRtrix using multiple threads."

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

  def install
    cp "LICENCE.txt", "#{prefix}/"
    bin.mkpath()
    system "mkdir", "#{prefix}/lib"
    system "mkdir", "#{prefix}/release"
    system "ln", "-s", "#{prefix}/bin", "#{prefix}/release/bin"

    system "mkdir", "#{prefix}/icons"
    cp_r 'icons/.', "#{prefix}/icons/"

    if build.include? "build_single_thread"
      ENV["NUMBER_OF_PROCESSORS"] = "1"
    end

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
    scripts = `find "#{prefix}/scripts" -type f -print0 | xargs -0 grep -l "lib.app.initParser"`
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

    # TODO: add matlab scripts to matlab path
    # TODO: mrtrix_bash_completion

    print "Installation done. You can find MRtrix in #{prefix}"

  end
end

