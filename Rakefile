require 'rake/testtask'
require 'rdoc/task'

task :console do
  exec 'irb -I lib -r activehistory.rb'
end
task :c => :console

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
end