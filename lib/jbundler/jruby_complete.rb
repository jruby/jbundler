require 'jbundler/pom_runner'
require 'fileutils'
module JBundler
  class JRubyComplete < PomRunner

    def initialize( config, options )
      super options
      work_dir = File.expand_path( config.work_dir )
      maven.property( 'jbundler.workdir', work_dir )
      maven.property( 'jbundler.basedir', config.basedir )
      maven.property( 'jbundler.jarfile', config.jarfile )
      maven.property( 'jbundler.gemfile', config.gemfile )
      @tree = File.join( work_dir, 'tree.txt' )
      maven.property( 'jbundler.outputFile', @tree )
    end

    def pom_file
      File.join( File.dirname( __FILE__ ), 'jruby_complete_pom.rb' )
    end

    def show_versions
      puts '...'

      FileUtils.rm_f( @tree )

      exec( 'dependency:tree' )

      if File.exist?( @tree )
        puts File.read( @tree )
      end
    end

    def packit
      puts '...'
      exec( :package )

      puts
      puts 'now you can use jruby like this'
      puts
      puts "\tjava -jar jruby_complete_custom.jar"
      puts
    end
  end
end
