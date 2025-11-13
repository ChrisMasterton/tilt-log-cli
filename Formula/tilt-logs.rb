

class TiltLogs < Formula
  desc "CLI tool to read logs from Docker containers managed by Tilt"
  homepage "https://github.com/chris/tilt-logs"
  version "v0.1.6"

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/chris/tilt-logs/releases/download/v0.1.6/tilt-logs-aarch64-apple-darwin.tar.gz"
    sha256 "REPLACE_WITH_REAL_SHA256"
  elsif OS.mac? && Hardware::CPU.intel?
    url "https://github.com/chris/tilt-logs/releases/download/v0.1.6/tilt-logs-x86_64-apple-darwin.tar.gz"
    sha256 "REPLACE_WITH_REAL_SHA256"
  else
    odie "Unsupported platform"
  end

  def install
    bin.install "tilt-logs"
  end

  def caveats
    <<~EOS
      tilt-logs installed!
      Usage examples:
        tilt-logs api
        tilt-logs backend --follow
        tilt-logs --list

      Make sure Docker is installed and running.
    EOS
  end

  test do
    system "#{bin}/tilt-logs", "--help"
  end
end