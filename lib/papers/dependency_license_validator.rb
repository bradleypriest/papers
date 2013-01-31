# This looks at a YAML manifest of gems and JS to
# a) make sure that the manifest matches what we're using
# b) make sure that the manifest knows their licenses
# c) make sure those licenses aren't dangerous

module Papers

class DependencyLicenseValidator
  def initialize
    @errors = []
  end

  def valid?
    @errors = []
    validate_gems
    validate_js
    @errors.empty?
  end

  def errors
    @errors
  end

  def manifest
    @manifest ||= YAML.load File.read(manifest_file)
  end

  private

  def validate_spec_type(spec_type)
    spec_type.missing_from_manifest(manifest).each do |name|
      errors << "#{name} is in the app, but not in the manifest"
    end

    spec_type.unknown_in_manifest(manifest).each do |name|
      errors << "#{name} is in the manifest, but not in the app"
    end

    spec_type.all_from_manifest(manifest).each do |spec|
      errors << "#{spec.name} is licensed under #{spec.license}, which is not acceptable" unless spec.acceptable_license?
    end
  end

  def validate_gems
    validate_spec_type GemSpec
  end

  def validate_js
    validate_spec_type JsSpec
  end

  def manifest_file
    File.join Rails.root, "config", "dependency_manifest.yml"
  end

  class DependencySpec < Struct.new(:name, :license)
    GOOD_LICENSES = ["MIT", "BSD", "LGPLv2.1", "LGPLv3", "Ruby", "Apache 2.0", "Perl Artistic", "Artistic 2.0", "ISC", "New Relic", "None", "Manually reviewed"]
    def acceptable_license?
      GOOD_LICENSES.include?(license)
    end

    def self.all_from_manifest(manifest)
      manifest[manifest_key].map {|name, license| new name, license}
    end

    def self.missing_from_manifest(manifest)
      introspected.to_set - all_from_manifest(manifest).map(&:name).to_set
    end

    def self.unknown_in_manifest(manifest)
      all_from_manifest(manifest).map(&:name).to_set - introspected.to_set
    end
  end

  class GemSpec < DependencySpec
    def self.introspected
      Bundler.load.specs.map do |spec|
        # bundler versions aren't controlled by the Gemfile
        if spec.name == "bundler"
          spec.name
        else
          "#{spec.name}-#{spec.version}"
        end
      end
    end

    def self.manifest_key
      "gems"
    end
  end

  class JsSpec < DependencySpec
    def self.introspected
      dirs = []
      dirs << File.join(Rails.root, "app", "assets", "javascripts")

      root_regexp = /^#{Regexp.escape Rails.root.to_s}\//
      dirs.map {|dir| Dir["#{dir}/**/*.js"]}.flatten.map {|name| name.sub(root_regexp, '')}
    end

    def self.manifest_key
      "javascripts"
    end
  end
end

end