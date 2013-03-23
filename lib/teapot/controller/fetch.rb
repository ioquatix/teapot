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

require 'teapot/controller'

module Teapot
	class Controller
		def fetch
			context, configuration = load_teapot

			resolved = Set.new
			unresolved = context.unresolved(configuration.packages)
			tries = 0

			while tries < @options[:maximum_fetch_depth]
				configuration.packages.each do |package|
					next if resolved.include? package
				
					destination_path = package.path
				
					if package.local?
						log "Linking local #{package}...".color(:cyan)
				
						local_path = context.root + package.options[:local]
			
						# Make the top level directory if required:
						destination_path.dirname.mkpath
			
						unless destination_path.exist?
							destination_path.make_symlink(local_path)
						end
					elsif package.external?
						log "Fetching #{package}...".color(:cyan)
		
						base_uri = URI(package.options[:source].to_s)

						if base_uri.scheme == nil || base_uri.scheme == 'file'
							base_uri = URI "file://" + File.expand_path(base_uri.path, context.root) + "/"
						end

						branch = package.options.fetch(:version, 'master')

						unless destination_path.exist?
							log "Cloning package at path #{destination_path} ...".color(:cyan)
					
							begin
								destination_path.mkpath

								external_url = package.external_url(context.root)

								Teapot::Commands.run("git", "clone", external_url, destination_path, "--branch", branch)
			
								Dir.chdir(destination_path) do
									Teapot::Commands.run("git", "submodule", "update", "--init", "--recursive")
								end
							rescue
								log "Removing incomplete package at path #{destination_path}...".color(:red)
						
								# Clean up if the git checkout process is interrupted:
								destination_path.rmtree
						
								raise
							end
						else
							log "Updating package at path #{destination_path} ...".color(:cyan)

							Dir.chdir(destination_path) do
								Teapot::Commands.run("git", "fetch", "origin")
				
								Teapot::Commands.run("git", "checkout", branch)
				
								# Pull any changes, if you might get the error from above:
								# Your branch is behind 'origin/0.1' by 1 commit, and can be fast-forwarded.
								Teapot::Commands.run("git", "pull")
				
								Teapot::Commands.run("git", "submodule", "update", "--init", "--recursive")
							end
						end
					end
				
					# We are done with this package, don't try to process it again:
					resolved << package
				end
			
				# Resolve any/all imports:
				configuration = configuration.materialize
			
				previously_unresolved = unresolved
				unresolved = context.unresolved(configuration.packages)
			
				# No additional packages were resolved, we have reached a fixed point:
				if previously_unresolved == unresolved || unresolved.count == 0
					break
				end
			
				tries += 1
			end
		
			if unresolved.count > 0
				log "Could not fetch all packages!".color(:red)
				unresolved.each do |package|
					log "\t#{package}".color(:red)
				end
			else
				log "Completed fetch successfully.".color(:green)
			end
		end
	end
end