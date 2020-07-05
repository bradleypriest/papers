require 'optparse'

module Papers

  class CLI

    def run
      options.parse!

      case @command
      when :generate
        Papers::ManifestGenerator.new.generate!
      when :update
        Papers::ManifestUpdater.new.update!
      when :validate
        validator = Papers::LicenseValidator.new
        if validator.valid?
          puts "All Licenses valid"
        else
          warn "License validation failed:\n#{validator.errors.join("\n")}"
        end
      when :help
        emit_help ""
      else
        emit_help "Unrecognized command."
      end
    rescue Papers::FileExistsError => e
      warn "Error: 'papers_manifest.yml' already exists at '#{e.message}'. Aborting..."
    rescue OptionParser::ParseError => e
      emit_help "Problem parsing options: #{e.message}"
    end

    private

    def options
      @options ||= OptionParser.new do |opts|
        opts.banner = 'Usage: papers [options]'

        opts.on('-g', '--generate', 'Generate papers_manifest.yml') do |v|
          @command = :generate
        end

        opts.on("-u", "--update", "Update papers_manifest.yml for Rubygems") do |v|
          @command = :update
        end

        opts.on("-r", "--run", "Run the license validator") do |v|
          @command = :validate
        end

        opts.on('-h', '--help', 'Display this screen') do
          @command = :help
        end
      end
    end

    def emit_help(header)
      unless header.empty?
        puts header
        puts
      end
      puts options
    end
  end
end
