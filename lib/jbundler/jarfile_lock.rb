#
# Copyright (C) 2014 Christian Meier
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
require 'jar_dependencies'
require 'maven/tools/dsl/jarfile_lock'
module JBundler
  class JarfileLock < Maven::Tools::DSL::JarfileLock

    def require( scope = :runtime )
      coordinates( scope ).each do |coord|
        Jars.require_jar( coord.split( /:/ ) )
      end
    end

    def classpath( scope = :runtime )
      coordinates( scope ).collect do |coord|
        path_to_jar( coord.split( /:/ ) )
      end
    end

    def downloaded?
      classpath.member?( nil ) == false &&
        classpath( :test ).member?( nil ) == false
    end

    private

    # TODO should move into jar-dependencies
    def to_path( group_id, artifact_id, *classifier_version )
      version = classifier_version[ -1 ]
      classifier = classifier_version[ -2 ]
      
      jar = to_jar( group_id, artifact_id, version, classifier )
      ( [ Jars.home ] + $LOAD_PATH ).each do |path|
        if File.exist?( f = File.join( path, jar ) )
          return f
        end
      end
      nil
    end
    
    # TODO this is copy and paste from jar-dependncies
    def to_jar( group_id, artifact_id, version, classifier )
      file = "#{group_id.gsub( /\./, '/' )}/#{artifact_id}/#{version}/#{artifact_id}-#{version}"
      file << "-#{classifier}" if classifier
      file << '.jar'
      file
    end
  end
end
