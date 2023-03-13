require "date"
require_relative "./lib/ravendb/version"

Gem::Specification.new do |spec|
  spec.name        = "ravendb"
  spec.version     = RavenDB::VERSION
  spec.summary     = "RavenDB"
  spec.description = "RavenDB client for Ruby"
  spec.authors     = ["Hibernating Rhinos"]
  spec.email       = "support@ravendb.net"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|example)/}) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("activesupport")
  spec.add_runtime_dependency("concurrent-ruby")
  spec.add_runtime_dependency("openssl")

  spec.add_development_dependency("rainbow", "~> 3.1.1")
  spec.add_development_dependency("rake", "~> 13.0.6")
  spec.add_development_dependency("rspec", "~> 3.12.0")
  spec.add_development_dependency("rubocop", "~> 1.48.1")
  spec.add_development_dependency("rubocop-rspec", "~> 2.19.0")
  spec.add_development_dependency("simplecov", "~> 0.22.0")

  spec.homepage = "http://ravendb.net"
  spec.license  = "MIT"
  spec.metadata["rubygems_mfa_required"] = "true"
end
