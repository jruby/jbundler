# jbundler

[![Gem Version](https://img.shields.io/gem/v/jbundler)](https://rubygems.org/gems/jbundler)
[![master Build Status](https://github.com/jruby/jbundler/actions/workflows/ci.yml/badge.svg)](https://github.com/jruby/jbundler/actions/workflows/ci.yml?query=branch%3Amaster) (master)

Manage jar dependencies similar to how **bundler** manages gem dependencies:

* the DSL mimics the one from bundler
* you can use maven-like version declarations or rubygems/bundler version ranges
* it locks down the jar versions inside "Jarfile.lock"
* you can declare jar dependencies within a gem using the requirements directive of the gem specification. jbundler will include those jar dependencies into its classpath

differences compared to **bundler**

* you need to run `bundle install` first if any of the gems have jar dependencies.
* all one command `jbundle`, see `jbundle help` on the possible options and how to update a single jar, etc.

## Get started

Install JBundler with:
```bash
jruby -S gem install jbundler
```

First, create a **Jarfile**, something like:
```bash
jar 'org.yaml:snakeyaml', '1.14'
jar 'org.slf4j:slf4j-simple', '>1.1'
```

Install jar dependencies
```bash
jruby -S jbundle install
```

Loading the jar files
```bash
require 'jbundler'
```

It will add all the jar dependencies in the java classpath from the `Jarfile.lock`.

### Jarfile

More info about the **[Jarfile](https://github.com/torquebox/maven-tools/wiki/Jarfile)** and about [versions](https://github.com/torquebox/maven-tools/wiki/Versions).

For adding a maven repository see [Jarfile](https://github.com/torquebox/maven-tools/wiki/Jarfile).

## Building the jbundler gem

Running the integration test

```bash
./mvnw verify
./mvnw clean verify
```
or a single integration test
```bash
./mvnw verify -Dinvoker.test=running_rspec_via_rake
./mvnw clean verify -Dinvoker.test=running_rspec_via_rake
```

Building the gem (see ./pkg)
```bash
./mvnw package -Dinvoker.skip
```

Or just
```bash
gem build jbundler.gemspec
```

## Usage

Here is an example usage of the AliasEvent class from the snakeyaml package

```ruby
#test_file.rb
require 'jbundler'
require 'java'

java_import 'org.yaml.snakeyaml.events.AliasEvent'

class TestClass
  def my_method
    puts AliasEvent.methods
  end
end

TestClass.new.my_method
```

## Limitations

Since the version resolution happens in two steps - first the gems, and then the jars/poms - it is possible in case of a failure that there is a valid gems/jars version resolution which satisfies all version contraints. So there is plenty of space for improvements (like maven could resolve the gems as well, etc).

## Special thanks

The whole project actually started with a controversial discussion on a [pull request on bundler](https://github.com/carlhuda/bundler/pull/1683). This very same pull request were the starting point of that project here. Probably by now there is not much left of the original code, but many thanks to [ANithian](https://github.com/ANithian) for giving the seed of that project.

License
-------

JBundler is [MIT-licensed](./MIT-LICENSE).

Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Meta-fu
-------

enjoy :)
