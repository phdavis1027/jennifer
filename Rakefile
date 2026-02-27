# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new do |t|
	t.libs << "examples"
	t.test_files = FileList["examples/test_*.rb"]
end

task default: :test
