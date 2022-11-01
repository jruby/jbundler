#
# Copyright (C) 2013 Christian Meier
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'bundler/vendored_thor'
require 'jbundler/config'
require 'jbundler/tree'
require 'jbundler/lock_down'
require 'jbundler/jruby_complete'
module JBundler
  # As of v1.9.0, bundler's vendored version of thor is namespaced
  Thor = Bundler::Thor if Gem.loaded_specs['bundler'].version >= Gem::Version.new('1.9.0')

  class Cli < Thor
    no_tasks do
      def config
        @config ||= JBundler::Config.new
      end

      def unvendor
        vendor = JBundler::Vendor.new( config.vendor_dir )
        vendor.clear
      end

      def vendor
        vendor = JBundler::Vendor.new( config.vendor_dir )
        if vendor.vendored?
          raise "already vendored. please 'jbundle install --no-deployment before."
        else
          vendor.setup( JBundler::ClasspathFile.new( config.classpath_file ) )
        end
      end

      def say_bundle_complete
        puts ''
        puts 'Your jbundle is complete! Use `jbundle show` to see where the bundled jars are installed.'
      end
    end

    desc 'tree', 'display a graphical representation of the dependency tree'
    #method_option :details, :type => :boolean, :default => false
    def tree
      JBundler::Tree.new( config ).show_it
    end

    desc 'install', "first `bundle install` is called and then the jar dependencies will be installed. for more details see `bundle help install`, jbundler will ignore most options. the install command is also the default when no command is given."
    method_option :vendor, :type => :boolean, :default => false, :desc => 'vendor jars into vendor directory (jbundler only).'
    method_option :debug, :type => :boolean, :default => false, :desc => 'enable maven debug output (jbundler only).'
    method_option :verbose, :type => :boolean, :default => false, :desc => 'enable maven output (jbundler only).'
    method_option :deployment, :type => :boolean, :default => false, :desc => "copy the jars into the vendor/jars directory (or as configured). these vendored jars have preference before the classpath jars !"
    method_option :no_deployment, :type => :boolean, :default => false, :desc => 'clears the vendored jars'
    method_option :path, :type => :string
    method_option :without, :type => :array
    method_option :system, :type => :boolean
    method_option :local, :type => :boolean
    method_option :binstubs, :type => :string
    method_option :trust_policy, :type => :string
    method_option :gemfile, :type => :string
    method_option :jobs, :type => :string
    method_option :retry, :type => :string
    method_option :no_cache, :type => :boolean
    method_option :quiet, :type => :boolean
    def install
      msg = JBundler::LockDown.new( config ).lock_down( options[ :vendor ],
                                                        options[ :debug ] ,
                                                        options[ :verbose ] )
      config.verbose = ! options[ :quiet ]
      Show.new( config ).show_classpath
      unless options[ :quiet ]
        puts 'jbundle complete !'
        puts
      end
      puts msg if msg
    end

    desc 'init', 'creates an empty Jarfile'
    def init
      if File.exists?('Jarfile')
        puts "Jarfile already exist in this folder"
        return
      end
      example_content = """# Example Usage
# jar 'org.yaml:snakeyaml', '1.14'
# jar 'org.slf4j:slf4j-simple', '>1.1'
"""
      file = File.open("Jarfile", 'w')
      file << example_content
      file.close
      msg = "Writing new Jarfile to #{Dir.pwd}/Jarfile"
      puts msg
    end

    desc 'console', 'irb session with gems and/or jars and with lazy jar loading.'
    def console
      # dummy - never executed !!!
    end

    desc 'lock_down', "first `bundle install` is called and then the jar dependencies will be installed. for more details see `bundle help install`, jbundler will ignore all options. the install command is also the default when no command is given. that is kept as fall back in cases where the new install does not work as before."
    method_option :deployment, :type => :boolean, :default => false, :desc => "copy the jars into the vendor/jars directory (or as configured). add the vendor/jars $LOAD_PATH and Jars.require_jars_lock! - no need for any jbundler files at runtime !"
    method_option :no_deployment, :type => :boolean, :default => false, :desc => 'clears the vendored jars'
    method_option :path, :type => :string
    method_option :without, :type => :array
    method_option :system, :type => :boolean
    method_option :local, :type => :boolean
    method_option :binstubs, :type => :string
    method_option :trust_policy, :type => :string
    method_option :gemfile, :type => :string
    method_option :jobs, :type => :string
    method_option :retry, :type => :string
    method_option :no_cache, :type => :boolean
    method_option :quiet, :type => :boolean
    def lock_down
      require 'jbundler'

      unvendor if options[ :no_deployment ]

      vendor if options[ :deployment ]

      config.verbose = ! options[ :quiet ]

      Show.new( config ).show_classpath

      say_bundle_complete unless options[ :quiet ]
    end

    desc 'update', "first `bundle update` is called and if there are no options then the jar dependencies will be updated. for more details see `bundle help update`."
    method_option :debug,   :type => :boolean, :default => false, :desc => 'enable maven debug output (jbundler only).'
    method_option :verbose, :type => :boolean, :default => false, :desc => 'enable maven output (jbundler only).'
    method_option :quiet,   :type => :boolean
    def update
      msg = JBundler::LockDown.new( config ).update( options[ :debug ] ,
                                                     options[ :verbose ] )

      config.verbose = ! options[ :quiet ]
      Show.new( config ).show_classpath
      unless options[ :quiet ]
        puts ''
        puts 'Your jbundle is updated! Use `jbundle show` to see where the bundled jars are installed.'
      end
      puts msg if msg
    end

    desc 'show', "first `bundle show` is called and if there are no options then the jar dependencies will be displayed. for more details see `bundle help show`."
    def show
      config.verbose = true
      Show.new( config ).show_classpath
    end
  end
end
