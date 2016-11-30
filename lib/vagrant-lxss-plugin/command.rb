require 'optparse'

module VagrantLxss
  class Command < Vagrant.plugin(2, :command)
    def self.synopsis
      "connects to a machine using Bash on Ubuntu on Windows"
    end

    def execute
      raise Vagrant::Errors::CapabilityHostNotDetected unless is_win_x?
      raise Vagrant::Errors::CapabilityNotFound unless is_bash_installed?

      options = {
        :help => false
      }

      opts = OptionParser.new do |o|
        o.banner = "Usage: vagrant bash [name|id]"
        o.separator ""

        o.on("-h", "--help", "Display command help") do |h|
          options[:help] = h
        end
      end

      argv = parse_options(opts)
      return -1 if !argv

      if options[:help]
        @logger.info('Connect to a machine using the Bash shell provided by \'Ubuntu on Windows\'')
        return 0
      end

      with_target_vms(argv) do |machine|
        ssh_info = machine.ssh_info
        raise Vagrant::Errors::SSHNotReady if ssh_info.nil?

        ssh_options = ["#{ssh_info[:username]}@#{ssh_info[:host]}"]
        ssh_options += ["-p #{ssh_info[:port]}"] if ssh_info[:port] != 22
        ssh_options += ["-A"] if ssh_info[:forward_agent]
        ssh_options += ["-v"]

        key_file = nil
        dir = nil
        if ssh_info[:private_key_path].any?
          ssh_info[:private_key_path].each { |path|
            if File.exists? path
              key_file = File.basename(path)
              dir = File.dirname(path)
              break
            end
          }
        end

        unless dir.nil? and dir.casecmp(Dir.pwd).zero?
          Dir.chdir(dir)
          ssh_options += [ "-i #{key_file}" ]
        end

        command = "C:\\Windows\\system32\\bash.exe -c 'ssh #{ssh_options.join(' ')}'"
        @logger.info("Full command: #{command}")
        output = system(command)
        @logger.info("Output: #{output}")
        return 0
      end
    end

    def is_bash_installed?
      system("C:\\Windows\\system32\\bash.exe -c 'echo \"hello\"'")
    end

    def is_win_x?
      false unless Gem.win_platform?
      result = `cmd /C ver`
      return result =~ /\[Version 10.*\]/
    end

    def convert_path (path)
      path = path.gsub '\\', '/'
      path = path.gsub (/^([A-Z])\:\//i) { '/mnt/' << $1.downcase << '/' }
      return path
    end
  end
end
