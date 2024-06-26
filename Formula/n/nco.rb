class Nco < Formula
  desc "Command-line operators for netCDF and HDF files"
  homepage "https://nco.sourceforge.net/"
  url "https://github.com/nco/nco/archive/refs/tags/5.2.5.tar.gz"
  sha256 "1053d3bf68c0b528502a545c9291747b9be7cb4938a2e48e08c7585462fc7d64"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "f99b3e3cb0f0977816cd52c294dbe051493130aa31e259699ada6652293599ef"
    sha256 cellar: :any,                 arm64_ventura:  "3a07487ba557428fa025cab2f00043a8ae3ff353637105536402be6983b4925d"
    sha256 cellar: :any,                 arm64_monterey: "b6604f1e84e8c164dd1cab34538a57ab94deeb014b561c2f22fc1ba2171617ca"
    sha256 cellar: :any,                 sonoma:         "ff10d433410240ff8b813e72df7fb0fd5bdbcf40979a756c9998a37126226715"
    sha256 cellar: :any,                 ventura:        "affef750919513bb351a0b5465dbd8c73fe422581d4bc239124c52123fb6301a"
    sha256 cellar: :any,                 monterey:       "5816068a6524f9ec4f52178c1e25e0f84fc8e51c067feb97a834b90c6a28fb24"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "45fed80dcb34438c967c4bf5e3a066f544672a9703458df17153e8891763ca2f"
  end

  head do
    url "https://github.com/nco/nco.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on "openjdk" => :build # needed for antlr2
  depends_on "gettext"
  depends_on "gsl"
  depends_on "netcdf"
  depends_on "texinfo"
  depends_on "udunits"

  uses_from_macos "flex" => :build

  resource "antlr2" do
    url "https://github.com/nco/antlr2/archive/refs/tags/antlr2-2.7.7-1.tar.gz"
    sha256 "d06e0ae7a0380c806321045d045ccacac92071f0f843aeef7bdf5841d330a989"
  end

  def install
    resource("antlr2").stage do
      system "./configure", "--prefix=#{buildpath}",
                            "--disable-debug",
                            "--disable-csharp"
      system "make"

      (buildpath/"libexec").install "antlr.jar"
      (buildpath/"include").install "lib/cpp/antlr"
      (buildpath/"lib").install "lib/cpp/src/libantlr.a"

      (buildpath/"bin/antlr").write <<~EOS
        #!/bin/sh
        exec "#{Formula["openjdk"].opt_bin}/java" -classpath "#{buildpath}/libexec/antlr.jar" antlr.Tool "$@"
      EOS

      chmod 0755, buildpath/"bin/antlr"
    end

    ENV.append "CPPFLAGS", "-I#{buildpath}/include"
    ENV.append "LDFLAGS", "-L#{buildpath}/lib"
    ENV.prepend_path "PATH", buildpath/"bin"
    system "./autogen.sh" if build.head?
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-netcdf4"
    system "make", "install"
  end

  test do
    resource "homebrew-example_nc" do
      url "https://www.unidata.ucar.edu/software/netcdf/examples/WMI_Lear.nc"
      sha256 "e37527146376716ef335d01d68efc8d0142bdebf8d9d7f4e8cbe6f880807bdef"
    end

    testpath.install resource("homebrew-example_nc")
    output = shell_output("#{bin}/ncks --json -M WMI_Lear.nc")
    assert_match "\"time\": 180", output
  end
end
