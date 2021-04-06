require 'spec_helper'

describe "gf mapping" do
  describe "Translations" do
    specify "finding a key" do
      write_file 'config/locales/en.yml', <<~EOF
        en:
          users:
            page:
              heading: "Users page"
      EOF

      edit_file 'app/views/users/index.erb', <<-EOF
        <%= t('users.page.heading') %>
      EOF
      vim.search 'users'
      vim.feedkeys('gf')

      expect(current_file).to eq 'config/locales/en.yml'
      expect(current_line).to include 'heading: "Users page"'
    end

    specify "finding a key in a nested file" do
      write_file 'config/locales/nested/en.yml', <<~EOF
        en:
          users:
            page:
              heading: "Users page"
      EOF

      edit_file 'app/views/users/index.erb', <<-EOF
        <%= t('users.page.heading') %>
      EOF
      vim.search 'users'
      vim.feedkeys('gf')

      expect(current_file).to eq 'config/locales/nested/en.yml'
      expect(current_line).to include 'heading: "Users page"'
    end

    specify "key duplication with nesting" do
      pending "Difficult case, needs some thinking"

      write_file 'config/locales/en.yml', <<~EOF
        en:
          nested:
            users:
              page:
                nested:
                  heading: "Wrong!"
          users:
            page:
              heading: "Users page"
      EOF

      edit_file 'app/views/users/index.erb', <<-EOF
        <%= t('users.page.heading') %>
      EOF
      vim.search 'users'
      vim.feedkeys('gf')

      expect(current_file).to eq 'config/locales/en.yml'
      expect(current_line).to include 'heading: "Users page"'
    end

    specify "partial matches" do
      write_file 'config/locales/en.yml', <<~EOF
        en:
          users:
            page:
              body: "Users body"
      EOF

      edit_file 'app/views/users/index.erb', <<-EOF
        <%= t('users.page.heading') %>
      EOF
      vim.search 'users'
      vim.feedkeys('gf')

      expect(current_file).to eq 'config/locales/en.yml'
      expect(current_line).to include 'page:'
    end
  end

  describe "Routes" do
    describe "controller#action" do
      before :each do
        write_file 'app/controllers/users_controller.rb', <<~EOF
          class UsersController < ApplicationController
            def index
            end

            def profile
            end
          end
        EOF
      end

      specify "route => target" do
        edit_file 'config/routes.rb', <<~EOF
          Rails.application.routes.draw do
            get 'route' => 'users#profile'
          end
        EOF

        vim.search 'users#profile'
        vim.feedkeys('gf')

        expect(current_file).to eq 'app/controllers/users_controller.rb'
        expect(current_line.strip).to eq 'def profile'
      end

      specify "to: target" do
        edit_file 'config/routes.rb', <<~EOF
          Rails.application.routes.draw do
            get 'route', to: 'users#profile'
          end
        EOF

        vim.search 'users#profile'
        vim.feedkeys('gf')

        expect(current_file).to eq 'app/controllers/users_controller.rb'
        expect(current_line.strip).to eq 'def profile'
      end

      specify ":to => target" do
        edit_file 'config/routes.rb', <<~EOF
          Rails.application.routes.draw do
            get 'route', :to => 'users#profile'
          end
        EOF

        vim.search 'users#profile'
        vim.feedkeys('gf')

        expect(current_file).to eq 'app/controllers/users_controller.rb'
        expect(current_line.strip).to eq 'def profile'
      end
    end

    specify "controller: and action: keys" do
      write_file 'app/controllers/admin/users_controller.rb', <<~EOF
        class Admin::UsersController < ApplicationController
          def index
          end

          def profile
          end
        end
      EOF

      edit_file 'config/routes.rb', <<~EOF
        Rails.application.routes.draw do
          match '/admin/users', controller: 'admin/users', action: 'profile', via: 'get'
        end
      EOF

      vim.search '\/admin\/users'
      vim.feedkeys('gf')

      expect(current_file).to eq 'app/controllers/admin/users_controller.rb'
      expect(current_line.strip).to eq 'def profile'
    end

    specify "controller do block" do
      write_file 'app/controllers/users_controller.rb', <<~EOF
        class UsersController < ApplicationController
          def index
          end

          def profile
          end
        end
      EOF

      edit_file 'config/routes.rb', <<~EOF
        Rails.application.routes.draw do
          controller :users do
            get 'users/profile', action: :profile
          end
        end
      EOF

      vim.search 'users\/profile'
      vim.feedkeys('gf')

      expect(current_file).to eq 'app/controllers/users_controller.rb'
      expect(current_line.strip).to eq 'def profile'
    end

    specify "controller do block is lower priority than an explicit one" do
      write_file 'app/controllers/users_controller.rb', <<~EOF
        class UsersController < ApplicationController
          def index
          end

          def profile
          end
        end
      EOF

      edit_file 'config/routes.rb', <<~EOF
        Rails.application.routes.draw do
          controller :other do
            get 'users/profile', controller: :users, action: :profile
          end
        end
      EOF

      vim.search 'users\/profile'
      vim.feedkeys('gf')

      expect(current_file).to eq 'app/controllers/users_controller.rb'
      expect(current_line.strip).to eq 'def profile'
    end

    specify "resources: jumps to index" do
      write_file 'app/controllers/users_controller.rb', <<~EOF
        class UsersController < ApplicationController
          def index
          end

          def profile
          end
        end
      EOF

      edit_file 'config/routes.rb', <<~EOF
        Rails.application.routes.draw do
          resources :users
        end
      EOF

      vim.search 'users'
      vim.feedkeys('gf')

      expect(current_file).to eq 'app/controllers/users_controller.rb'
      expect(current_line.strip).to eq 'def index'
    end

    specify "resource: jumps to show" do
      write_file 'app/controllers/profiles_controller.rb', <<~EOF
        class ProfilesController < ApplicationController
          def index
          end

          def show
          end
        end
      EOF

      edit_file 'config/routes.rb', <<~EOF
        Rails.application.routes.draw do
          resource :profile
        end
      EOF

      vim.search 'profile'
      vim.feedkeys('gf')

      expect(current_file).to eq 'app/controllers/profiles_controller.rb'
      expect(current_line.strip).to eq 'def show'
    end

    specify "resources: member action" do
      write_file 'app/controllers/users_controller.rb', <<~EOF
        class UsersController < ApplicationController
          def index
          end

          def profile
          end
        end
      EOF

      edit_file 'config/routes.rb', <<~EOF
        Rails.application.routes.draw do
          resources :users do
            member do
              get :profile
            end
          end
        end
      EOF

      vim.search 'profile'
      vim.feedkeys('gf')

      expect(current_file).to eq 'app/controllers/users_controller.rb'
      expect(current_line.strip).to eq 'def profile'
    end

    specify "resource: member action" do
      write_file 'app/controllers/users_controller.rb', <<~EOF
        class UsersController < ApplicationController
          def index
          end

          def profile
          end
        end
      EOF

      edit_file 'config/routes.rb', <<~EOF
        Rails.application.routes.draw do
          resource :user do
            member do
              get :profile
            end
          end
        end
      EOF

      vim.search 'profile'
      vim.feedkeys('gf')

      expect(current_file).to eq 'app/controllers/users_controller.rb'
      expect(current_line.strip).to eq 'def profile'
    end

    describe "namespaces" do
      specify "using `namespace`" do
        write_file 'app/controllers/app/right/users_controller.rb', <<~EOF
          class App::Right::UsersController < ApplicationController
            def index
            end

            def show
            end
          end
        EOF

        edit_file 'config/routes.rb', <<~EOF
          Rails.application.routes.draw do
            namespace :app do
              namespace :right do
                namespace :wrong do
                  resource :other
                end

                test do
                  resources :users
                end
              end
            end
          end
        EOF

        vim.search 'users'
        vim.feedkeys('gf')

        expect(current_file).to eq 'app/controllers/app/right/users_controller.rb'
        expect(current_line.strip).to eq 'def index'
      end

      specify "using `scope`" do
        write_file 'app/controllers/app/bar/users_controller.rb', <<~EOF
          class App::Bar::UsersController < ApplicationController
            def index
            end

            def show
            end
          end
        EOF

        edit_file 'config/routes.rb', <<~EOF
          Rails.application.routes.draw do
            scope :app, module: 'app' do
              scope "foo", module: 'bar' do
                resources :users
              end
            end
          end
        EOF

        vim.search 'users'
        vim.feedkeys('gf')

        expect(current_file).to eq 'app/controllers/app/bar/users_controller.rb'
        expect(current_line.strip).to eq 'def index'
      end
    end

    specify "messy cases" do
      write_file 'app/controllers/site/home_controller.rb', <<~EOF
        class App::Bar::UsersController < ApplicationController
          def index
          end

          def example_action
          end
        end
      EOF

      edit_file 'config/routes.rb', <<~EOF
        Rails.application.routes.draw do
          scope :module => "site" do
            some_other_block do
              controller :home do
                get '/example', :action => 'example_action'
              end
            end
          end
        end
      EOF

      vim.search 'example_action'
      vim.feedkeys('gf')

      expect(current_file).to eq 'app/controllers/site/home_controller.rb'
      expect(current_line.strip).to eq 'def example_action'
    end

    specify "in config/routes/*.rb" do
      write_file 'app/controllers/users_controller.rb', <<~EOF
        class UsersController < ApplicationController
          def index
          end
        end
      EOF

      edit_file 'config/routes/test.rb', <<~EOF
        Rails.application.routes.draw do
          resources :users
        end
      EOF

      vim.search 'users'
      vim.feedkeys('gf')

      expect(current_file).to eq 'app/controllers/users_controller.rb'
      expect(current_line.strip).to eq 'def index'
    end
  end

  describe "Factories" do
    specify "jumps to a factory definition from a `create` call" do
      write_file 'test/factories.rb', <<~EOF
        FactoryBot.define do
          factory :other do
          end

          factory :user do
          end
        end
      EOF

      edit_file 'app/controllers/users_controller.rb', <<~EOF
        user = create :user, name: "Placeholder"
      EOF

      vim.search ':\zsuser'
      vim.feedkeys('gf')

      expect(current_file).to eq 'test/factories.rb'
      expect(current_line.strip).to eq 'factory :user do'
    end

    specify "jumps to a factory definition from a `create_list` call" do
      write_file 'test/factories.rb', <<~EOF
        FactoryBot.define do
          factory :other do
          end

          factory :user do
          end
        end
      EOF

      edit_file 'app/controllers/users_controller.rb', <<~EOF
        users = create_list :user, 2, name: "Placeholder"
      EOF

      vim.search ':\zsuser'
      vim.feedkeys('gf')

      expect(current_file).to eq 'test/factories.rb'
      expect(current_line.strip).to eq 'factory :user do'
    end
  end

  describe "RSpec matchers" do
    specify "locates a custom RSpec matcher" do
      touch_file 'spec/support/matchers/wibble_and_wobble_matcher.rb'
      edit_file 'spec/lib/basic_spec.rb', <<~EOF
        expect(timey_wimey_stuff).to wibble_and_wobble
      EOF

      vim.search 'wibble'
      vim.feedkeys('gf')

      expect(current_file).to eq 'spec/support/matchers/wibble_and_wobble_matcher.rb'
    end
  end
end
