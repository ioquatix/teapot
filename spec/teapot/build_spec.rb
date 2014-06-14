# Copyright, 2014, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'teapot/build'
require 'teapot/environment'

module Teapot::BuildSpec
	class DummyTarget
		def name
			"dummy-target"
		end
		
		def build
			lambda do
				# This is technically incorrect, because this Top graph node specifies no outputs. But, for testing, it's fine.
				fs.touch "bob"
			end
		end
	end
	
	describe Teapot::Build do
		let(:environment) {Teapot::Environment.hash(foo: 'bar')}
		
		it "should create a simple build graph" do
			expect(FileUtils::NoWrite).to receive(:touch).with("bob").once
			expect(FileUtils::Verbose).to receive(:touch).with("bob").once
			
			controller = Teapot::Build::Controller.new do |controller|
				controller.add_target(DummyTarget.new, environment)
			end
			
			controller.update!
		end
	end
end