run_test_patch = <<-EOS
diff --git a/run_tests b/run_tests
index a9dd80320..bd5fb9133 100755
--- a/run_tests
+++ b/run_tests
@@ -10,6 +10,10 @@ cat > $LOGFILE <<EOD

 EOD

+no_fetch=${1:-do_fetch}
+no_build=${2:-do_build}
+
+if [ $no_fetch != no_fetch ]; then
 echo -n "fetching test data... "
 git submodule update --init >> $LOGFILE 2>&1

@@ -19,9 +23,12 @@ if [ $? != 0 ]; then
 else
   echo OK
 fi
+else
+  shift
+fi


-
+if [ $no_build != no_build ]; then
 echo -n "building testing commands... "
 cat >> $LOGFILE <<EOD

@@ -30,9 +37,10 @@ cat >> $LOGFILE <<EOD
 ## building test commands...

 EOD
+
 (
   cd testing
-  ../build
+  ../build -nopaginate
 ) >> $LOGFILE 2>&1
 if [ $? != 0 ]; then
   echo ERROR!
@@ -40,6 +48,9 @@ if [ $? != 0 ]; then
 else
   echo OK
 fi
+else
+  shift
+fi


 # generate list of tests to run:
EOS


class Mrtrix30rc3 < Formula
  desc "MRtrix3: tools to perform various types of diffusion MRI analyses."

  homepage "http://mrtrix.org"

  url "https://github.com/MRtrix3/mrtrix3.git"

  version  '3.0_RC3-0-g57e351eb'
  revision 1

  option "test", "Run tests after installation."
  option "assert", "Build with assert statements (executables are slower)."
  option "debug", "Build with debug statements (executables are slower)."
  option "mrconvert", "Build mrconvert, no other binaries unless stated"
  option "mrinfo", "Build mrinfo, no other binaries unless stated"
  option "mrview", "Build mrview, no other binaries unless stated"
  option "without-multithreaded_build", "This is useful if your computer has many cores but not enough RAM to build MRtrix using multiple threads."
  option "without-matlab", "Do not add MRtrix scripts to matlab path."
  option "with-copy_src_from_home", "Use MRtrix3 source code from ~/mrtrix3. This settting is for developers and testing purposes!"

  depends_on "python" => :recommended
  depends_on "eigen" => :build
  depends_on "pkg-config"
  depends_on "qt5"

  conflicts_with "mrtrix3", :because => "tagged version (this) conflicts with non-tagged version of mrtrix3." 

  bottle do
    root_url "https://github.com/MRtrix3/mrtrix3/releases/download/3.0_RC3"
    rebuild 0
    cellar :any
    sha256 "5483cefd60aa12fe2039997588b055e811863c65b75577e96da06a8b0ea96edd" => :high_sierra
  end

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
    matlab_add = <<-EOS
import os, glob, sys, subprocess

# Trick out homebrew's overwrite of USER
p = subprocess.Popen('whoami', shell = True, stdout=subprocess.PIPE)
me = p.stdout.readline().rstrip()
p.wait()

comment='% MRtrix3 PATH automatically generated by homebrew installation formula - do NOT modify:'
set_path = "addpath('#{prefix}/matlab')" + os.linesep

def path_has_been_set(startup):
    if not os.path.isfile(startup):
        return False
    with open (startup, "r") as inp:
        for iline, line in enumerate(inp):
            if comment in line:
                nl = next(inp)
                if not 'mrtrix' in nl.lower():
                    raise Exception ('matlab startup file ' + startup + ' has been modified. aborting. ' + nl)
                return iline + 1
    return 0

matlab_bins = glob.glob("/Applications/MATLAB_R20*/bin/matlab")
if not len(matlab_bins):
    print ("WARNING: no Matlab binary found. Not adding MRtrix to Matlab startup path")
    sys.exit(0)

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
    try:
        pline = path_has_been_set(startup)
        if pline:
            with open (startup, "r") as inp:
                sf = inp.readlines()
                sf[pline] = set_path + os.linesep
            with open (startup, "w") as inp:
                inp.write(''.join(sf))
            print ("updated mrtrix path in " + startup)
        else:
            with open (startup, "a") as inp:
                inp.write(comment + os.linesep + set_path + os.linesep)
            print ("added mrtrix path to " + startup)
        is_set += 1
    except:
        print "WARNING: could not set mrtrix path in Matlab startup file: " + startup
if not (is_set):
    raise Exception('could not set mrtrix path in any Matlab startup file')
EOS
      open(pkgshare+'/matlab_add.py', 'w') do |f|
        f.puts matlab_add
      end
      system "python", pkgshare+'/matlab_add.py'
      rm pkgshare+'/matlab_add.py'
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

    system "git", "fetch", "--unshallow"
    system "git", "reset",  "--hard", "origin/master"      
    system "git", "checkout", "#{version}"

    if build.without? "multithreaded_build"
      ENV["NUMBER_OF_PROCESSORS"] = "1"
      print "NUMBER_OF_PROCESSORS = 1"
    end

    conf = [ "./configure"]
    # if build.without? "qt5"
    #   conf.push("-nogui")
    # end
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
      if build.include? "mrview"
        bld.push("release/bin/mrview")
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
      cp "configure.log", pkgshare

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
      if build.include? "mrview"
        bld.push("bin/mrview")
      end
      execute (bld.join(" "))


      # This has to be before bin.install or else binaries are not in place.
      if build.include? "test"
        tst = [ "./run_tests"]
        if build.include? "mrconvert"
          tst.push("mrconvert")
        end
        execute (tst.join(" "))
        system "mkdir", "#{prefix}/testing"
        cp_r 'testing/.', "#{prefix}/testing/"
        
        # patch run_tests tests to not fetch the data and not build
        open('run_test_patch.diff', 'w') do |f|
          f.puts un_test_patch
        end
        system "python", "matlab_add.py"
        execute("git apply run_test_patch.diff")
        rm 'run_test_patch.diff'

        cp_r 'run_tests', "#{prefix}"
        cp "testing.log", "#{prefix}"
        print "Testing done. Testlog is in #{pkgshare}\n"
      end

      execute("git rev-parse HEAD > #{pkgshare}/git_hash")
      bin.install Dir["bin/*"]
      system "mkdir", "#{prefix}/lib"
      cp_r 'lib/.', "#{prefix}/lib/"
      cp "config", pkgshare

    end

    # TODO: mrtrix_bash_completion

  end

  def post_install
    if build.without? "matlab"
      print "ignoring Matlab"
    else
      begin
        set_matlab_path()
      rescue Exception => bang
        print "Warning: unable to set Matlab path: " + bang.to_s + "\n"
        print "You can add it manually to your startup.m: " + "addpath('#{prefix}/matlab')\n"
      end
    end
    print "Installation done. The MRtrix3 binaries are in #{prefix}/bin\n"
    print "\n"
    print "⚠️: If you have an existing version of MRtrix3 in your PATH\n"
    print "and want to use this version without prepending '$(brew --prefix)/bin' to your commands,\n"
    print "make sure to remove the previous version from your PATH.\n"
    print "You can find out with 'ls -l $(which mrinfo)'\n"
    print "\n"
    # print "Alternatively, rename its folder or prepend your PATH with #{prefix}/bin\n"
    print "For more information go to http://mrtrix.readthedocs.io\n"
  end


  test do
    if build.include? "test"
      puts "#{prefix}"
      puts testpath
      cp_r "#{prefix}/.", testpath # mrtrix directory is not writable, testpath is
      cd testpath
      system ("./run_tests no_fetch no_build")
    end
  end
end

