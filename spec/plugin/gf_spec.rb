require 'spec_helper'

describe "gf mapping" do
  describe "Translations" do
    specify "finding a translation key" do
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
      vim.command 'normal gf'

      expect(current_file).to eq 'config/locales/en.yml'
      expect(current_line).to include 'heading: "Users page"'
    end

    # TODO (2020-05-06) Other translation files
    # TODO (2020-05-06) Missing translation keys
  end

  describe "Asset imports" do
    specify "following SCSS imports" do
      touch_file 'app/assets/stylesheets/other.scss'
      edit_file 'app/assets/stylesheets/application.scss', <<~EOF
        @import 'other';
      EOF

      vim.search 'other'
      vim.command 'normal gf'

      expect(current_file).to eq 'app/assets/stylesheets/other.scss'
    end

    specify "following javascript requires" do
      touch_file 'app/assets/javascripts/other.js'
      edit_file 'app/assets/javascripts/application.js', <<~EOF
        //= require other
      EOF

      vim.search 'other'
      vim.command 'normal gf'

      expect(current_file).to eq 'app/assets/javascripts/other.js'
    end

    specify "following coffeescript imports" do
      touch_file 'app/assets/javascripts/other.js'
      edit_file 'app/assets/javascripts/application.coffee', <<~EOF
        #= require other
      EOF

      vim.search 'other'
      vim.command 'normal gf'

      expect(current_file).to eq 'app/assets/javascripts/other.js'
    end

    specify "following CSS requires" do
      touch_file 'app/assets/stylesheets/other.css'
      edit_file 'app/assets/stylesheets/application.css', <<~EOF
        /*
         * = require other
         */
      EOF

      vim.search 'other'
      vim.command 'normal gf'

      expect(current_file).to eq 'app/assets/stylesheets/other.css'
    end
  end

  describe "Routes" do
    specify "jumps to a particular controller, on a particular action" do
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
          get '/users/profile' => 'users#profile'
        end
      EOF

      vim.search 'users#profile'
      vim.command 'normal gf'

      expect(current_file).to eq 'app/controllers/users_controller.rb'
      expect(current_line.strip).to eq 'def profile'
    end

    specify "jumps to a route defined with explicit controller and action" do
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
      vim.command 'normal gf'

      expect(current_file).to eq 'app/controllers/admin/users_controller.rb'
      expect(current_line.strip).to eq 'def profile'
    end

    # TODO (2020-05-06) Resource, resources
    # TODO (2020-05-06) explicit controller pattern
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
      vim.command 'normal gf'

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
      vim.command 'normal gf'

      expect(current_file).to eq 'spec/support/matchers/wibble_and_wobble_matcher.rb'
    end
  end
end
