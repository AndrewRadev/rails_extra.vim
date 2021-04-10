require 'spec_helper'

describe ":Epath" do
  before :each do
    # Stub out `rake routes` for `rails#app().routes()`
    write_file 'routes.txt', <<~EOF
               Prefix Verb   URI Pattern            Controller#Action
                 root GET    /                      pages#index
           login_page GET    /pages/login(.:format) pages#login
            show_page GET    /pages/:id/show        pages#show
        catchall_page GET    /pages/catchall*       pages#catchall
      namespaced_page GET    /admin/users           admin/users#index
    EOF
    write_file 'Rakefile', <<~EOF
      task :routes do
        puts IO.read('routes.txt')
      end
    EOF

    write_file 'app/controllers/pages_controller.rb', <<~EOF
      class PagesController < ApplicationController
        def index
        end

        def login
        end

        def show
        end

        def catchall
        end
      end
    EOF

    write_file 'app/controllers/admin/users_controller.rb', <<~EOF
      class Admin::UsersController < ApplicationController
        def index
        end
      end
    EOF
  end

  it "jumps to a given path" do
    edit_file 'test.rb'
    expect(current_file).to eq 'test.rb'

    vim.command 'Epath /'
    expect(current_file).to eq 'app/controllers/pages_controller.rb'
    expect(current_line.strip).to eq 'def index'

    edit_file 'test.rb'
    vim.command 'Epath /pages/login'

    expect(current_file).to eq 'app/controllers/pages_controller.rb'
    expect(current_line.strip).to eq 'def login'

    edit_file 'test.rb'
    vim.command 'Epath /pages/42/show'

    expect(current_file).to eq 'app/controllers/pages_controller.rb'
    expect(current_line.strip).to eq 'def show'

    edit_file 'test.rb'
    vim.command 'Epath /pages/catchall-foo/bar'

    expect(current_file).to eq 'app/controllers/pages_controller.rb'
    expect(current_line.strip).to eq 'def catchall'

    edit_file 'test.rb'
    vim.command 'Epath /admin/users'

    expect(current_file).to eq 'app/controllers/admin/users_controller.rb'
    expect(current_line.strip).to eq 'def index'
  end

  it "handles localhost URLs" do
    edit_file 'test.rb'
    expect(current_file).to eq 'test.rb'

    vim.command 'Epath http://localhost:3000/pages/login'

    expect(current_file).to eq 'app/controllers/pages_controller.rb'
    expect(current_line.strip).to eq 'def login'

    edit_file 'test.rb'
    vim.command 'Epath http://127.0.0.1:1234/pages/login'

    expect(current_file).to eq 'app/controllers/pages_controller.rb'
    expect(current_line.strip).to eq 'def login'
  end

  it "handles production URLs" do
    edit_file 'test.rb'
    expect(current_file).to eq 'test.rb'

    vim.command 'Epath https://production-url.com/pages/login'

    expect(current_file).to eq 'app/controllers/pages_controller.rb'
    expect(current_line.strip).to eq 'def login'
  end

  it "ignores query params" do
    edit_file 'test.rb'
    expect(current_file).to eq 'test.rb'

    vim.command 'Epath /pages/login?some=query'

    expect(current_file).to eq 'app/controllers/pages_controller.rb'
    expect(current_line.strip).to eq 'def login'
  end
end
