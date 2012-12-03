#!/usr/bin/env rake
require "bundler/setup"

desc "run the specs"
task :spec do
  sh "rspec -cfs spec"
end

task :default => :spec

desc "build the gem"
task :build do
  system "gem build localeapp-handlebars_i18n.gemspec"
end
desc "build and release the gem"
task :release => :build do
  system "gem push localeapp-handlebars_i18n-#{Localeapp::HandlebarsI18n::VERSION}.gem"
end
