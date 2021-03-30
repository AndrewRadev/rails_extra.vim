task :default do
  sh 'rspec spec'
end

desc "Prepare archive for deployment"
task :archive do
  sh 'zip -r ~/rails_extra.zip autoload/ doc/rails_extra.txt plugin/'
end
