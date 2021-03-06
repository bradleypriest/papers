module Papers
  class ManifestCommand
    def initialize(manifest_path = nil)
      @manifest_path = manifest_path || File.join('config', 'papers_manifest.yml')
    end

    def manifest_exists?
      File.exist?(@manifest_path)
    end

    def build_header
      [
        "# Dependency Manifest for the Papers gem",
        "# Used to test your gems and javascript against license whitelist",
        "#",
        "# http://github.com/newrelic/papers\n"
      ].join("\n")
    end

    def get_installed_gems
      gems = {}
      Bundler.load.specs.each do |spec|
        gems[gem_name_and_version(spec)] = gem_entry(spec)
      end
      return gems
    end

    def get_installed_javascripts
      js = {}
      Javascript.introspected.each do |entry|
        js[entry] = {
          'license'     => 'Unknown',
          'license_url' => nil,
          'project_url' => nil
        }
      end
      js.empty? ? nil : js
    end

    def get_installed_bower_components
      components = {}
      BowerComponent.full_introspected_entries.each do |entry|
        components[entry['name']] = {
          'license' => 'Unknown',
          'license_url' => nil,
          'project_url' => ensure_valid_url(entry['homepage'])
        }
      end
      components.empty? ? nil : components
    end

    def get_installed_npm_packages
      packages = {}
      NpmPackage.full_introspected_entries.each do |entry|
        packages[entry['name']] = {
          'license' => 'Unknown',
          'license_url' => nil,
          'project_url' => nil
        }
      end
      packages.empty? ? nil : packages
    end

    def gem_name_and_version(spec)
      if spec.name == 'bundler'
        name_and_version = spec.name
      else
        name_and_version = "#{spec.name}-#{spec.version}"
      end
    end

    def gem_entry(spec)
      gem_license     = blank?(spec.license) ? fetch_gem_license(spec) : spec.license
      gem_project_url = blank?(spec.homepage) ? nil : spec.homepage

      {
        'license'     => gem_license,
        'license_url' => nil,
        'project_url' => ensure_valid_url(gem_project_url)
        # TODO: add support for multiple licenses? some gemspecs have dual licensing
      }
    end

    def fetch_gem_license(spec)
      ['LICENSE', 'LICENSE.md', 'LICENSE.txt', 'MIT-LICENSE.txt', 'MIT-LICENSE'].reduce(nil) do |iter, path|
        next iter if iter
        next 'MIT' if ['MIT-LICENSE.txt', 'MIT-LICENSE'].include?(path)
        next iter unless File.exist?(File.join(spec.full_gem_path, path))

        extract_license(File.read(File.join(spec.full_gem_path, path)))
      end || 'Unknown'
    end

    # TODO: Use licensee
    def extract_license(license)
      case license
      when /MIT License/
        'MIT'
      end
    end

    def blank?(str)
      str.to_s.empty?
    end

    def ensure_valid_url(url_string)
      match_url = URI::regexp.match(url_string)
      if match_url.nil?
        nil
      else
        match_url[0]
      end
    end
  end
end
