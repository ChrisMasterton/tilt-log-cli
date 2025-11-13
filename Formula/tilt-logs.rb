

class TiltLogs < Formula
  desc "CLI tool to read logs from Docker containers managed by Tilt"
  homepage "https://github.com/ChrisMasterton/tilt-log-cli"
  version "v0.1.6"

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/ChrisMasterton/tilt-log-cli/releases/download/v0.1.6/tilt-logs-aarch64-apple-darwin.tar.gz"
    sha256 "6e83979c64fd610aaafbc9b00c7ff3a9bc6748c0de7d84910e1123bac075e474"
  elsif OS.mac? && Hardware::CPU.intel?
    url "https://github.com/ChrisMasterton/tilt-log-cli/releases/download/v0.1.6/tilt-logs-x86_64-apple-darwin.tar.gz"
    sha256 "4c9a0c9ed666342adc1bcc71673dd900a8bc8fc245c529f67ce683cadd01e061"
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