class Blast < Formula
  desc "Basic Local Alignment Search Tool"
  homepage "http://blast.ncbi.nlm.nih.gov/"
  # doi "10.1016/S0022-2836(05)80360-2"
  # tag "bioinformatics"

  url "ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.3.0/ncbi-blast-2.3.0+-src.tar.gz"
  mirror "http://mirrors.vbi.vt.edu/mirrors/ftp.ncbi.nih.gov/blast/executables/blast+/2.3.0/ncbi-blast-2.3.0%2b-src.tar.gz"
  version "2.3.0"
  sha256 "7ce8dc62f58141b6cdcd56b55ea3c17bea7a672e6256dfd725e6ef94825e94e9"

  bottle do
    sha256 "7e6af104bc9d79796c7f2443661f1514a4190dcb19434c9d545b08a2ade99999" => :el_capitan
    sha256 "114d859491dd7806c74576bed446cdbc1a76b6854307a641e5da1485d570e1ff" => :yosemite
    sha256 "70f6c059193d5e50055f4582048af3f8eb3b17c7958c1b153c18c3503636d074" => :mavericks
  end

  # Fix configure: error: Do not know how to build MT-safe with compiler g++-5 5.1.0
  fails_with :gcc => "5"

  # Due to boost 1.58
  fails_with :llvm do
    build 2335
    cause "Dropped arguments to functions when linking with boost"
  end

  option "with-static", "Build without static libraries and binaries"
  option "with-dll", "Build dynamic libraries"

  depends_on "freetype" => :optional
  depends_on "gnutls" => :optional
  depends_on "hdf5" => :optional
  depends_on "jpeg" => :recommended
  depends_on "libpng" => :recommended
  depends_on "lzo" => :optional
  depends_on :mysql => :optional
  depends_on "pcre" => :recommended
  depends_on :python if MacOS.version <= :snow_leopard

  def install
    # The libraries and headers conflict with ncbi-c++-toolkit so use libexec.
    args = %W[
      --prefix=#{prefix}
      --libdir=#{libexec}
      --without-debug
      --with-mt
      --without-boost
    ]

    args << (build.with?("mysql") ? "--with-mysql" : "--without-mysql")
    args << (build.with?("freetype") ? "--with-freetype=#{Formula["freetype"].opt_prefix}" : "--without-freetype")
    args << (build.with?("gnutls") ? "--with-gnutls=#{Formula["gnutls"].opt_prefix}" : "--without-gnutls")
    args << (build.with?("jpeg")   ? "--with-jpeg=#{Formula["jpeg"].opt_prefix}" : "--without-jpeg")
    args << (build.with?("libpng") ? "--with-png=#{Formula["libpng"].opt_prefix}" : "--without-png")
    args << (build.with?("pcre")   ? "--with-pcre=#{Formula["pcre"].opt_prefix}" : "--without-pcre")
    args << (build.with?("hdf5")   ? "--with-hdf5=#{Formula["hdf5"].opt_prefix}" : "--without-hdf5")

    if build.without? "static"
      args << "--with-dll" << "--without-static" << "--without-static-exe"
    else
      args << "--with-static"
      args << "--with-static-exe" unless OS.linux?
      args << "--with-dll" if build.with? "dll"
    end

    cd "c++"

    # The build invokes datatool but its linked libraries aren't installed yet.
    ln_s buildpath/"c++/ReleaseMT/lib", prefix/"libexec" if build.without? "static"

    system "./configure", *args
    system "make"

    rm prefix/"libexec" if build.without? "static"

    system "make", "install"

    # The libraries and headers conflict with ncbi-c++-toolkit.
    libexec.install include
  end

  def caveats; <<-EOS.undent
    Using the option "--with-static" will create static binaries instead of
    dynamic. The NCBI Blast static installation is approximately 7 times larger
    than the dynamic.

    Static binaries should be used for speed if the executable requires fast
    startup time, such as if another program is frequently restarting the blast
    executables.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/blastn -version")
  end
end
