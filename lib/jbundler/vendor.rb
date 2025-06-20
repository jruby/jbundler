require 'jars/installer'
module JBundler
  class Vendor

    def initialize( dir )
      @dir = File.expand_path( dir )
      @jars_lock = File.join( @dir, 'Jars.lock' )
    end

    def vendored?
      File.exists?( @dir ) && Dir[ File.join( @dir, '*' ) ].size > 0
    end

    def require_jars
      if File.exists?(@jars_lock)
        $LOAD_PATH << @dir unless $LOAD_PATH.include? @dir
        ENV_JAVA['jars.lock'] = @jars_lock
        Jars.require_jars_lock!
        true
      else
        require_jars_legacy
      end
    end

    def require_jars_legacy
      jars = File.join( @dir, 'jbundler.rb' )
      if File.exists?( jars )
        $LOAD_PATH << @dir unless $LOAD_PATH.include? @dir
        require jars
      else
        Dir[ File.join( @dir, '**', '*' ) ].each do |f|
          require f
        end
        Jars.no_more_warnings
        true
      end
    end

    def clear
      FileUtils.mkdir_p( @dir )
      Dir[ File.join( @dir, '*' ) ].each do |f|
        FileUtils.rm_rf( f )
      end
    end

    def vendor_dependencies( deps )
      FileUtils.mkdir_p( @dir )
      File.open(@jars_lock, 'w') do |f|
        deps.each do |dep|
          if dep.scope == :runtime
            target = File.join( @dir, dep.path )
            FileUtils.mkdir_p( File.dirname( target ) )
            FileUtils.cp( dep.file, target )
            line = dep.gav + ':runtime:'
            f.puts line
          end
        end
      end
      ['jbundler.rb', 'jbundle.rb'].each do |filename|
        File.write( File.join( @dir, filename ), 
                    "ENV['JARS_LOCK'] = File.join( File.dirname( __FILE__ ), 'Jars.lock' )\nrequire 'jars/setup'" )
      end
    end

    def setup( classpath_file )
      classpath_file.require_classpath
      FileUtils.mkdir_p( @dir )
      JBUNDLER_CLASSPATH.each do |f|
        FileUtils.cp( f, File.join( @dir,
                                    File.basename( f ) ) )
      end
    end
  end
end

