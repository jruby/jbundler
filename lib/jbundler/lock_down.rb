require 'jbundler/configurator'
require 'jbundler/classpath_file'
require 'jbundler/vendor'
require 'jbundler/gemfile_lock'
require 'jbundler/show'
require 'maven/tools/gemspec_dependencies'
require 'maven/tools/jarfile'
require 'maven/ruby/maven'
require 'fileutils'
require 'jars/installer'

module JBundler
  class LockDown

    def initialize( config )
      @config = config
      @configurator = Configurator.new( config )
    end
    
    def vendor
      @vendor ||= JBundler::Vendor.new( @config.vendor_dir )
    end

    def update( debug = false, verbose = false )
      if vendor.vendored?
        raise 'Cannot update vendored jars'
      end

      FileUtils.rm_f( @config.jarfile_lock )
      
      lock_down( false, debug, verbose )
    end
    
    def lock_down( needs_vendor = false, debug = false, verbose = false )
      jarfile = Maven::Tools::Jarfile.new( @config.jarfile )
      classpath = JBundler::ClasspathFile.new( @config.classpath_file )
      if jarfile.exists_lock? && classpath.exists?
        needs_update = false
      else
        needs_update = needs_update?( jarfile, classpath )
      end
      if ( ! needs_update && ! needs_vendor ) || vendor.vendored?

        puts 'Jar dependencies are up to date !'

        if needs_update?( jarfile, classpath )
          f = classpath.file.sub(/#{Dir.pwd}#{File::SEPARATOR}/, '' )
          "the #{f} is stale, i.e. Gemfile or Jarfile is newer. `jbundle update` will update it"
        end
      else

        puts '...'
       
        deps = install_dependencies( debug, verbose, jarfile.exists_lock? )

        update_files( classpath, collect_jars( deps ) ) if needs_update

        vendor_it( vendor, deps ) if needs_vendor

      end
    end

    private

    def needs_update?( jarfile, classpath )
      gemfile_lock = JBundler::GemfileLock.new( jarfile, 
                                                @config.gemfile_lock )
      classpath.needs_update?( jarfile, gemfile_lock )
    end

    def vendor_it( vendor, deps )
      puts "vendor directory: #{@config.vendor_dir}"
      vendor.vendor_dependencies( deps )
      puts
    end

    def collect_jars( deps )
      jars = {}
      deps.each do |d|
        case d.scope
        when :provided
          ( jars[ :jruby ] ||= [] ) << d
        when :test
          ( jars[ :test ] ||= [] ) << d
        else
          ( jars[ :runtime ] ||= [] ) << d
        end
      end
      jars
    end

    def update_files( classpath_file, jars )
      if jars.values.flatten.size == 0
        FileUtils.rm_f @config.jarfile_lock
      else
        lock = Maven::Tools::DSL::JarfileLock.new( @config.jarfile )
        lock.replace( jars )
        lock.dump
      end
      classpath_file.generate( (jars[ :runtime ] || []).collect { |j| j.file },
                               (jars[ :test ] || []).collect { |j| j.file },
                               (jars[ :jruby ] || []).collect { |j| j.file },
                               @config.local_repository )
    end

    def install_dependencies( debug, verbose, exclude_transitive = false )
      deps_file = File.join( File.expand_path( @config.work_dir ), 
                               'dependencies.txt' )
 
      exec_maven( debug, verbose, deps_file, exclude_transitive )

      result = []
      File.read( deps_file ).each_line do |line|
        dep = Jars::JarInstaller::Dependency.new( line )
        result << dep if dep
      end
      result
    ensure
      FileUtils.rm_f( deps_file ) if deps_file
    end

    def exec_maven( debug, verbose, output, exclude_transitive = false )
      m = Maven::Ruby::Maven.new
      m.options[ '-f' ] = File.join( File.dirname( __FILE__ ), 
                                     'dependency_pom.rb' )
      m.property( 'verbose', debug || verbose )
      m.options[ '-q' ] = nil if !debug and !verbose
      m.options[ '-e' ] = nil if !debug and verbose
      m.options[ '-X' ] = nil if debug
      m.options[ '-DexcludeTransitive' ] = exclude_transitive
      m.verbose = debug
      m.property( 'jbundler.outputFile', output )

      @configurator.configure( m )

      attach_jar_coordinates( m )

      m.exec( 'dependency:list' )
    end

    private

    def attach_jar_coordinates( maven )
      load_path = $LOAD_PATH.dup
      require 'bundler/setup'
      done = []
      index = 0
      Gem.loaded_specs.each do |name, spec|
        # TODO get rid of this somehow
        deps = Maven::Tools::GemspecDependencies.new( spec )
        deps.java_dependency_artifacts.each do |a|
          if not done.include?( a.key ) and (a.scope.nil? or a.scope == :compile or a.scope == :runtime)
            maven.property( "jbundler.jars.#{index}", a.to_s )
            index += 1
            done << a.key
          end
        end
      end
      if index > 0
        maven.property( "jbundler.jars.size", index )
      end
    ensure
      $LOAD_PATH.replace( load_path )
    end
  end
end
