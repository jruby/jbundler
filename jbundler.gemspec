#-*- mode: ruby -*-

Gem::Specification.new do |s|
  s.name = 'jbundler'
  s.version = '0.9.4'

  s.summary = 'managing jar dependencies'
  s.description = <<-END
managing jar dependencies with or without bundler. adding bundler like handling of version ranges for jar dependencies.
END

  s.authors = ['Christian Meier']
  s.email = ['m.kristian@web.de']
  s.homepage = 'https://github.com/mkristian/jbundler'

  s.bindir = "bin"
  s.executables = ['jbundle']

  s.license = 'MIT'

  s.files += Dir['lib/**/*.rb']
  s.files += Dir['spec/*.rb']
  s.files += Dir['spec/*/*'].delete_if { |f| f =~ /~$/ }
  s.files += Dir['MIT-LICENSE']
  s.files += Dir['*.md']
  s.files += Dir['Gemfile*']
  s.test_files += Dir['spec/*_spec.rb']

  s.add_runtime_dependency 'maven-tools', '1.2.3'

  s.add_runtime_dependency "ruby-maven", "~> 3.3", '>= 3.3.8'
  s.add_runtime_dependency "bundler", "> 1.5", "< 3.0.0"
  s.add_runtime_dependency "jar-dependencies", "~> 0.3"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "minitest", "~> 5.3"
end
