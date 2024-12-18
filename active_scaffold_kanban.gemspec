# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'active_scaffold_kanban/version'

Gem::Specification.new do |s|
  s.name = %q{active_scaffold_kanban}
  s.version = ActiveScaffoldKanban::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.email = %q{activescaffold@googlegroups.com}
  s.authors = ["Sergio Cambra"]
  s.homepage = %q{https://activescaffold.eu}
  s.summary = %q{Show records as kanban board, using ActiveScaffold}
  s.description = %q{User may reorder records and change to a different column}
  s.require_paths = ["lib"]
  s.files = `git ls-files -- app config lib`.split("\n") + %w[LICENSE README.md]
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.licenses = ["MIT"]

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.add_runtime_dependency(%q<active_scaffold>, [">= 3.7.11"])
  s.add_runtime_dependency(%q<active_scaffold_sortable>, [">= 3.2.2"])
  s.add_runtime_dependency(%q<active_scaffold_config_list>, [">= 3.6.0"])
end
