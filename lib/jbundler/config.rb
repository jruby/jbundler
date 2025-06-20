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
require 'yaml'
require 'jar_dependencies'

module JBundler

  # allow yaml config in $HOME/.jbundlerrc and $PWD/.jbundlerrc
  class Config

    RC_FILE = '.jbundlerrc'

    attr_accessor :verbose, :local_repository, :jarfile, :gemfile, :skip, :settings, :offline, :work_dir, :vendor_dir, :basedir

    def initialize
      if ENV.has_key? 'HOME'
        homefile = File.join(ENV['HOME'], RC_FILE)
        home_config = YAML.load_file(homefile) if File.exist?(homefile)
      else
        home_config = nil
      end
      @config = (home_config || {})
      @basedir = find_basedir( File.expand_path( '.' ) )
      @basedir ||= File.expand_path( '.' )
      file = join_basedir( RC_FILE )
      pwd_config = YAML.load_file(file) if File.exist?(file)
      @config.merge!(pwd_config || {})
    end
    
    def join_basedir( path )
      if @basedir
        File.join( @basedir, path )
      else
        path
      end
    end

    def find_basedir( dir )
      f = File.join( dir, RC_FILE )
      return dir if File.exist?( f )
      f = File.join( dir, _jarfile )
      return dir if File.exist?( f )
      f = File.join( dir, _gemfile )
      return dir if File.exist?( f )
      parent = File.dirname( dir )
      if dir != ENV['HOME'] && dir != parent
        find_basedir( parent )
      end
    end

    def absolute( file )
      if file.nil? || file == File.expand_path( file )
        file
      else
        File.join( @basedir, file )
      end
    end

    def _jbundler_env( key )
      ENV[ key.upcase.gsub( /[.]/, '_' ) ] ||
        @config[ key.downcase.sub(/^j?bundle_/, '' ).sub( /[.]/, '_' ) ]
    end
    private :_jbundler_env

    if defined? JRUBY_VERSION
      def jbundler_env( key )
        java.lang.System.getProperty( key.downcase.gsub( /_/, '.' ) ) ||
          _jbundler_env( key )
      end
    else
      alias :jbundler_env :_jbundler_env
    end
    private :jbundler_env

    def skip
      skip = jbundler_env('JBUNDLE_SKIP')
      # defaults to false
      @skip ||= skip && skip != 'false'
    end

    def verbose
      verbose = jbundler_env('JBUNDLE_VERBOSE')
      # defaults to false
      @verbose ||= verbose && verbose != 'false'
    end

    def jarfile
      @jarfile ||= absolute( _jarfile )
    end

    def _jarfile
      jbundler_env('JBUNDLE_JARFILE') || 'Jarfile'
    end
    private :_jarfile

    def jarfile_lock
      "#{jarfile}.lock"
    end

    def gemfile
      @gemfile ||= absolute( _gemfile )
    end

    def _gemfile
      jbundler_env('BUNDLE_GEMFILE') || 'Gemfile'
    end
    private :_gemfile

    def gemfile_lock
      "#{gemfile}.lock"
    end

    def classpath_file
      absolute( jbundler_env('JBUNDLE_CLASSPATH_FILE') ||
                '.jbundler/classpath.rb' )
    end

    def local_repository
      # use maven default local repo as default
      local_maven_repository = absolute( jbundler_env('JBUNDLE_LOCAL_REPOSITORY') )
      if local_maven_repository
        warn "JBUNDLE_LOCAL_REPOSITORY environment or jbundle.local.repository' system property is deprecated use JARS_HOME or jars.home instead"
        ENV[ 'JARS_HOME' ] ||= local_maven_repository
      else
        # first load the right settings
        self.settings
        Jars.home
      end
    end

    def settings
      settings = absolute( jbundler_env('JBUNDLE_SETTINGS') )
      if settings
        warn "JBUNDLE_SETTINGS environment or jbundle.settings' system property is deprecated use JARS_MAVEN_SETTINGS or jars.maven.settings instead"
        ENV[ Jars::MAVEN_SETTINGS ] ||= settings
      end
      Jars.maven_settings
    end

    def offline
      @offline ||= jbundler_env('JBUNDLE_OFFLINE')
      @offline == 'true' || @offline == true
    end

    def proxy
      @proxy ||= jbundler_env('JBUNDLE_PROXY')
      if @proxy
        warn 'proxy config is deprecated, use settings.xml instead'
      end
      @proxy
    end

    def mirror
      @mirror ||= jbundler_env('JBUNDLE_MIRROR')
      # nice to have no leading slash
      @mirror = @mirror.sub( /\/$/, '' ) if @mirror
      if @mirror
        warn 'mirror config is deprecated, use settings.xml instead'
      end
      @mirror
    end

    def work_dir
      @work_dir ||= absolute( jbundler_env('JBUNDLE_WORK_DIR') || 'pkg' )
    end

    def vendor_dir
      @vendor_dir ||= absolute( jbundler_env('JBUNDLE_VENDOR_DIR') ||
                                File.join( 'vendor', 'jars' ) )
    end

  end
end
