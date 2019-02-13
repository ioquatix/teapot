# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'pathname'
require 'build/dependency'
require_relative 'definition'

require 'build/environment'
require 'build/rulebook'

module Teapot
	class BuildError < StandardError
	end
	
	class Target < Definition
		include Build::Dependency
		
		def initialize(*)
			super
			
			@build = nil
		end
		
		def freeze
			return self if frozen?
			
			@build.freeze
			
			super
		end
		
		def build(&block)
			if block_given?
				@build = block
			end
			
			return @build
		end
		
		# Given a specific configuration, generate the build environment based on this target and it's provision chain.
		def environment(configuration, chain, resolution)
			chain = chain.partial(self)
			
			# Calculate the dependency chain's ordered environments:
			environments = chain.provisions.collect do |provision|
				Build::Environment.new(name: provision.name, &provision.value)
			end
			
			return nil if environments.empty? and @build.nil?
			
			paths = Build::Environment.new(name: configuration.name) do
				build_path configuration.build_path
				platforms_path configuration.build_path
			end
			
			# Merge all the environments together:
			environment = Build::Environment.combine(paths, *environments)
			
			if @build
				environment = Build::Environment.new(environment, name: self.name, &@build)
			end
			
			if value = resolution.provision.value
				environment = Build::Environment.new(environment, name: resolution.provision.name, &value)
			end
			
			return environment
		end
	end
end
