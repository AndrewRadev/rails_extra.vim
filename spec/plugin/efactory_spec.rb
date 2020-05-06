require 'spec_helper'

describe ":Efactory" do
  it "jumps to a particular factory in a single factories.rb file" do
    touch_file 'spec/factories.rb'
    write_file 'spec/factories.rb', <<~EOF
      FactoryBot.define do
        factory :foo do
        end

        factory :bar do
        end
      end
    EOF

    edit_file 'test.rb'
    expect(current_file).to eq 'test.rb'

    vim.command 'Efactory foo'
    expect(current_file).to eq 'spec/factories.rb'
    expect(current_line).to include 'factory :foo'

    vim.command 'Efactory bar'
    expect(current_file).to eq 'spec/factories.rb'
    expect(current_line).to include 'factory :bar'
  end

  it "jumps to a particular factory file" do
    touch_file 'spec/support/factories/foo.rb'
    write_file 'spec/support/factories/foo.rb', <<~EOF
      FactoryBot.define do
        factory :foo do
        end
      end
    EOF

    touch_file 'spec/support/factories/bar.rb'
    write_file 'spec/support/factories/bar.rb', <<~EOF
      FactoryBot.define do
        factory :bar do
        end
      end
    EOF

    edit_file 'test.rb'
    expect(current_file).to eq 'test.rb'

    vim.command 'Efactory foo'
    expect(current_file).to eq 'spec/support/factories/foo.rb'
    expect(current_line).to include 'factory :foo'

    vim.command 'Efactory bar'
    expect(current_file).to eq 'spec/support/factories/bar.rb'
    expect(current_line).to include 'factory :bar'
  end

  it "autocompletes factory names from all factory files" do
    touch_file 'spec/factories.rb'
    write_file 'spec/factories.rb', <<~EOF
      FactoryBot.define do
        factory :foo do
        end

        factory :bar do
        end
      end
    EOF

    touch_file 'spec/factories/user.rb'
    write_file 'spec/factories/user.rb', <<~EOF
      FactoryBot.define do
        factory :user do
        end
      end
    EOF

    touch_file 'spec/support/factories/product.rb'
    write_file 'spec/support/factories/product.rb', <<~EOF
      FactoryBot.define do
        factory :product do
        end
      end
    EOF

    edit_file 'test.rb'
    tables = vim.command('echo rails_extra#edit#CompleteFactories("", "", "")')

    expect(tables.split("\n")).to match_array ['foo', 'bar', 'user', 'product']
  end
end
