
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
  desc "MRtrix3: tools to perform various types of diffusion MRI analyses."

  homepage "http://mrtrix.org"

  url "https://github.com/MRtrix3/mrtrix3.git"

  version  '3.0_RC1-77-g287865da'
  revision 1
  # devel do
  #   url 'https://github.com/MRtrix3/mrtrix3.git', :branch => 'master', :revision => 'bogus474279845b7e79fc2b5ffad'
  #   version '0.3_dev'
  # end

  option "stable", "Install latest tagged stable version. Default is last commit on master branch."
  option "test", "Run tests after installation."
  option "assert", "Build with assert statements (executables are slower)."
  option "debug", "Build with debug statements (executables are slower)."
  option "mrconvert", "Build mrconvert, no other binaries unless stated"
  option "mrinfo", "Build mrinfo, no other binaries unless stated"
  option "without-multithreaded_build", "This is useful if your computer has many cores but not enough RAM to build MRtrix using multiple threads."
  option "without-matlab", "Do not add MRtrix scripts to matlab path."
  option "with-copy_src_from_home", "Use MRtrix3 source code from ~/mrtrix3. This settting is for developers and testing purposes!"

  depends_on :python => :recommended
  depends_on "eigen" => :build
  depends_on "pkg-config" => :run
  # depends_on "qt5" # not used as users might want to use an existing qt or install mrtrix without a GUI
  depends_on Qt5Requirement => :recommended

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
      import os, glob, sys, subprocess

      # Trick out homebrew's overwrite of USER
      p = subprocess.Popen('whoami', shell = True, stdout=subprocess.PIPE)
      me = p.stdout.readline().rstrip()
      p.wait()

      def path_is_set(startup):
          if not os.path.isfile(startup):
              return False
          with open (startup, "r") as inp:
              for line in inp:
                  if "#{prefix}/matlab" in line:
                      return True
          return False

      matlab_bins = glob.glob("/Applications/MATLAB_R20*/bin/matlab")
      if not len(matlab_bins):
          print ("WARNING: no matlab binary found")

      startup_locations = []
      for bin in matlab_bins:
          matlab_root = os.path.split(os.path.split(bin)[0])[0]
          startup_locations.append(os.path.join(matlab_root, "toolbox", "local", "startup.m"))

      userdir = os.path.join('/Users',me,'Documents','MATLAB')
      if os.path.isdir(userdir):
          startup_locations.append(os.path.join(userdir,"startup.m"))
      else:
        print userdir + " not found"

      is_set = 0
      for startup in startup_locations:
          if not path_is_set(startup):
              try:
                  with open (startup, "a") as inp:
                      inp.write("addpath('#{prefix}/matlab')" + os.linesep )
                  print ("added mrtrix path to " + startup)
                  is_set += 1
              except:
                  print "WARNING: could not set mrtrix path in Matlab startup file: " + startup
          else:
              print ("mrtrix path already set in " + startup)
              is_set += 1
      if not (is_set):
          raise Exception('could not set mrtrix path in any Matlab startup file')
      EOS
      open('matlab_add.py', 'w') do |f|
        f.puts matlab_add
      end
      system "python", "matlab_add.py"
      rm 'matlab_add.py'
  end

  def install
    puts "PATH:"
    puts ENV["PATH"]
    if ENV["PATH"].downcase.include? "anaconda"
      puts "warning: anaconda found in PATH. You might want to exclude those directories from you PATH."
    end
    xcodeerror=`xcodebuild 2>&1`
    # puts xcodeerror
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

    if build.without? "matlab"
      print "ignoring Matlab"
    else
      begin
        set_matlab_path()
      rescue BuildError => bang
        print "Unable to set Matlab path: " + bang.to_s + "\n"
      end
    end

    if build.without? "multithreaded_build"
      ENV["NUMBER_OF_PROCESSORS"] = "1"
      print "NUMBER_OF_PROCESSORS = 1"
    end

    conf = [ "./configure"]
    if build.without? "qt5"
      conf.push("-nogui")
    end
    if build.include? "assert"
      conf.push("-assert")
    end
    if build.include? "debug"
      conf.push("-debug")
    end

    if build.with? "copy_src_from_home"
      me = `whoami`.strip
      external_mrtrix_src_dir = "/Users/"+me+"/mrtrix3"
      if not File.directory?("#{external_mrtrix_src_dir}")
        raise "not found: "+external_mrtrix_src_dir+". --with-copy_src_from_home is intended for developers only"
      end
      execute("rm -r *")
      execute("cp -r "+external_mrtrix_src_dir+"/* ./")
    end

    execute (conf.join(" "))
    bin.mkpath()
    pkgshare.mkpath()
    cp "LICENCE.txt", "#{prefix}/"
    cp "LICENCE.txt", "#{pkgshare}/"

    system "git", "reset", "head"
    system "git", "log", "-1"
    system "git", "describe", "--always", "--dirty"

    env = %x[env]
    puts "shared path: #{pkgshare}"
    File.open("#{pkgshare}/env", 'w') { |file| file.write(env) }

    if File.directory?("release") # pre tag 0.3.16

      system "mkdir", "#{prefix}/lib"
      system "mkdir", "#{prefix}/release"
      system "ln", "-s", "#{prefix}/bin", "#{prefix}/release/bin"

      system "mkdir", "#{prefix}/matlab"
      cp_r 'matlab/.', "#{prefix}/matlab/"

      system "mkdir", "#{prefix}/icons"
      cp_r 'icons/.', "#{prefix}/icons/"

      # copy and link scripts
      system "mkdir", "#{prefix}/scripts"
      cp_r 'scripts/.', "#{prefix}/scripts/"
      # find scripts that have lib.app.initParser and add others manually
      scripts = `find "#{prefix}/scripts" -type f ! -name "*.*" -maxdepth 1`
      scripts = scripts.split(" ")
      scripts = scripts.uniq.sort
      for scrpt in scripts
        print "linking "+Pathname(scrpt).each_filename.to_a[-1]+"\n"
        # bin.install_symlink prefix/"scripts/"Pathname(scrpt).each_filename.to_a[-1]
        system "ln", "-s", scrpt, "#{prefix}/bin/"+Pathname(scrpt).each_filename.to_a[-1]
      end

      bld = [ "./build"]
      if build.include? "mrconvert"
        bld.push("release/bin/mrconvert")
      end
      if build.include? "mrinfo"
        bld.push("release/bin/mrinfo")
      end
      execute (bld.join(" "))

      # This has to be before bin.install or else binaries are not in place.
      if build.include? "test"
        tst = [ "./run_tests"]
        if build.include? "mrconvert"
          tst.push("mrconvert")
        end
        execute (tst.join(" "))
        cp "testing.log", pkgshare
        print "Testing done. Testlog is in #{pkgshare}\n"
      end

      execute("git rev-parse HEAD > #{pkgshare}/git_hash")
      bin.install Dir["release/bin/*"]
      cp_r 'release/lib/.', "#{prefix}/lib/"
      cp "release/config", pkgshare

    else # >= tag_0.3.16
      cp "config", pkgshare

      system "mkdir", "#{prefix}/matlab"
      cp_r 'matlab/.', "#{prefix}/matlab/"

      system "mkdir", "#{prefix}/icons"
      cp_r 'icons/.', "#{prefix}/icons/"

      bld = [ "./build"]
      if build.include? "mrconvert"
        bld.push("bin/mrconvert")
      end
      if build.include? "mrinfo"
        bld.push("bin/mrinfo")
      end
      execute (bld.join(" "))


      # This has to be before bin.install or else binaries are not in place.
      if build.include? "test"
        tst = [ "./run_tests"]
        if build.include? "mrconvert"
          tst.push("mrconvert")
        end
        execute (tst.join(" "))
        cp "testing.log", pkgshare
        print "Testing done. Testlog is in #{pkgshare}\n"
      end


      execute("git rev-parse HEAD > #{pkgshare}/git_hash")
      bin.install Dir["bin/*"]
      system "mkdir", "#{prefix}/lib"
      cp_r 'lib/.', "#{prefix}/lib/"
      cp "config", pkgshare

    end

    # TODO: mrtrix_bash_completion

    print "Installation done. MRtrix3 lives in #{prefix}\n"
    print "For more information go to http://mrtrix.readthedocs.io\n"

  end

  # test do
  #   if build.with? "copy_src_from_home"
  #     me = `whoami`.strip
  #     external_mrtrix_src_dir = "/Users/"+me+"/mrtrix3"
  #     if not File.directory?("#{external_mrtrix_src_dir}")
  #       raise "not found: "+external_mrtrix_src_dir+". --with-copy_src_from_home is intended for developers only"
  #     end
  #     execute("rm -r *")
  #     execute("cp -r "+external_mrtrix_src_dir+" #{testpath}/mrtrix3")
  #   else
  #     execute("git clone https://github.com/MRtrix3/mrtrix3.git #{testpath}/mrtrix3")
  #   end

  #   cd "mrtrix3"
  #   githash = File.open("#{pkgshare}/git_hash") {|f| f.readline}
  #   execute("git checkout #{githash}")
  #   system "git", "log", "-1"
  #   # TODO: use config also for tests
  #   # cp "#{pkgshare}/config","config"
  #   # cp_r "#{prefix}/lib/", "lib"
  #   # mkdir "release"
  #   # cp "#{pkgshare}/config","release/config"
  #   begin
  #     execute("./configure -nogui")
  #     execute("./run_tests")
  #   rescue
  #     execute("echo 'Unable to run tests.")
  #   end
  #   execute("if tests failed: rerun with debug flag `brew test -d mrtrix3`, go to #{testpath} and inspect testing.log")
  #   system false # `brew test -d mrtrix3` will stop here
  #   # execute("cat testing.log")
  # end
end

