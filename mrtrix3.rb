  class Qt5Requirement < Requirement
  fatal true

  satisfy :build_env => false do
    @qmake = which('qmake')
    # @qmake = HOMEBREW_PREFIX"/opt/qt5/bin/qmake"
    @qmake
  end
  
  env do
    ENV.append_path 'PATH', @qmake.parent
  end
  
  def message
    message = <<-EOS.undent
      Homebrew was unable to find an installation of Qt 5. You can install it manually or with
      brew install qt5

      and make sure that it is found with
      export PATH=`brew --prefix`/opt/qt5/bin:$PATH
      or
      brew link --force qt5
    EOS
  end
end

ENV['LIBLEPT_HEADERSDIR'] = HOMEBREW_PREFIX/"include"

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
  version "0.3.15"
  sha256 "abce25cde2870abc8bd487f44f061d3e3bd42f36618519b740b7f5e74eba1e20"

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

    if build.include? "build_single_thread"
      ENV["NUMBER_OF_PROCESSORS"] = "1"
    end

    conf = [ "./configure" ]
    if build.include? "without-qt5"
      conf.push("-nogui")
    end
    execute (conf.join(" "))

    execute ("./build")

    bin.install Dir["release/bin/*"]
    bin.install Dir["scripts/*"]
  end
end

