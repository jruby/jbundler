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
module JBundler

  class ClasspathFile

    def initialize(classpathfile = '.jbundler/classpath.rb')
      @classpathfile = classpathfile
    end
    
    def file
      @classpathfile
    end

    def load_classpath
      load File.expand_path @classpathfile
    end

    def require_classpath
      load_classpath
      JBUNDLER_CLASSPATH.each { |c| require c }
    end

    def require_test_classpath
      load_classpath
      JBUNDLER_TEST_CLASSPATH.each { |c| require c }
    end

    def mtime
      File.mtime(@classpathfile)
    end

    def exists?
      File.exist?(@classpathfile)
    end

    def missing?( jarfile )
      !exists? || !jarfile.exists_lock?
    end

    def jarfile_newer?( jarfile )
      jarfile.exists? && (jarfile.mtime > mtime)
    end

    def jarlock_newer?( jarfile )
      jarfile.exists_lock? && (jarfile.mtime_lock > mtime)
    end
       
    def needs_update?(jarfile, gemfile_lock)
      if ( jarfile.exists? || gemfile_lock.exists? || jarfile.exists_lock? )
        missing?( jarfile ) || jarfile_newer?( jarfile ) || jarlock_newer?( jarfile ) || gemfile_lock.newer?( mtime )
      else
        false
      end
    end

    def generate( classpath_array, test_array = [], jruby_array = [], local_repo = nil )
      FileUtils.mkdir_p(File.dirname(@classpathfile))
      File.open(@classpathfile, 'w') do |f|
        if local_repo
          local_repo = File.expand_path( local_repo )
          f.puts "require 'jar_dependencies'"
          f.puts "JBUNDLER_LOCAL_REPO = Jars.home"
        end
        dump_array( f, jruby_array || [], 'JRUBY_', local_repo )
        dump_array( f, test_array || [], 'TEST_', local_repo )
        dump_array( f, classpath_array || [], '', local_repo )
        f.close
      end
    end
    
    private
    def dump_array( file, array, prefix, local_repo )
      file.puts "JBUNDLER_#{prefix}CLASSPATH = []"
      array.each do |path|
        dump_jar( file, path, prefix, local_repo )
      end
      file.puts "JBUNDLER_#{prefix}CLASSPATH.freeze"
    end

    def dump_jar( file, path, prefix, local_repo )
      return if path =~ /pom$/
      if local_repo
        path = path.sub( /#{local_repo}/, '' )
        unless File.exist?( path )
          file.puts "JBUNDLER_#{prefix}CLASSPATH << (JBUNDLER_LOCAL_REPO + '#{path}')"
          path = nil
        end
      end
      if path
        # either we do not have a local_repo or the path is a absolute
        # path from system artifact
        file.puts "JBUNDLER_#{prefix}CLASSPATH << '#{path}'"        
      end
    end
  end
end
