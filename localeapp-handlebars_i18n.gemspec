require File.expand_path('../lib/localeapp-handlebars_i18n/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Randy Morgan"]
  gem.email         = ["digital.ipseity@gmail.com"]
  gem.description   = %q{A localeapp reporter for working with handlebars templates with localizations.}
  gem.summary       = %q{Parses handlebars templates for localization helpers and adds missing keys to localeapp.}
  gem.homepage      = "http://github.com/randym/localeapp-handlebars_i18n"
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {spec}/*`.split("\n")
  gem.name          = "localeapp-handlebars_i18n"
  gem.require_paths = ["lib"]
  gem.version       = Localeapp::HandlebarsI18n::VERSION

  gem.add_dependency "localeapp"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rack"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "yard"
  gem.add_development_dependency "simplecov"
end
