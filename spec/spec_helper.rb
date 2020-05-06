require 'vimrunner'
require 'vimrunner/rspec'
require_relative './support/vim'

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  plugin_path = Pathname.new(File.expand_path('.'))

  config.start_vim do
    vim = Vimrunner.start_gvim
    vim.add_plugin(plugin_path.join('spec/support/vim-rails'), 'plugin/rails.vim')
    vim.add_plugin(plugin_path, 'plugin/rails_extra.vim')

    # bootstrap filetypes
    vim.command 'autocmd BufNewFile,BufRead *.coffee set filetype=coffee'
    vim.command 'autocmd BufNewFile,BufRead *.scss set filetype=scss'

    vim
  end
end

RSpec.configure do |config|
  config.include Support::Vim

  config.before do
    # Ensure enough of a rails-like structure exists for vim-rails to detect
    FileUtils.mkdir('app') if not File.exists?('app')
    FileUtils.mkdir('config') if not File.exists?('config')
    FileUtils.touch('config/environment.rb')
  end
end
