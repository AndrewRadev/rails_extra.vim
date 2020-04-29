require 'spec_helper'

describe ":Eschema" do
  it "opens the schema.rb file" do
    touch_file 'db/schema.rb'
    edit_file 'test.rb'
    expect(current_file).to eq 'test.rb'

    vim.command 'Eschema'

    expect(current_file).to eq 'db/schema.rb'
  end

  it "opens a structure.sql file" do
    touch_file 'db/structure.sql'
    edit_file 'test.rb'
    expect(current_file).to eq 'test.rb'

    vim.command 'Eschema'

    expect(current_file).to eq 'db/structure.sql'
  end

  it "jumps to a particular table" do
    touch_file 'db/schema.rb'
    write_file 'db/schema.rb', <<~EOF
      ActiveRecord::Schema.define(version: 1337) do
        create_table "foos", force: :cascade do |t|
        end

        create_table "bars", force: :cascade do |t|
        end
      end
    EOF

    edit_file 'test.rb'
    expect(current_file).to eq 'test.rb'

    vim.command 'Eschema foos'
    expect(current_file).to eq 'db/schema.rb'
    expect(current_line).to include 'create_table "foos"'

    vim.command 'Eschema bars'
    expect(current_file).to eq 'db/schema.rb'
    expect(current_line).to include 'create_table "bars"'
  end

  it "autocompletes schema tables from schema.rb" do
    touch_file 'db/schema.rb'
    write_file 'db/schema.rb', <<~EOF
      ActiveRecord::Schema.define(version: 1337) do
        create_table "foos", force: :cascade do |t|
        end

        create_table "bars", force: :cascade do |t|
        end
      end
    EOF

    edit_file 'test.rb'
    tables = vim.command('echo rails_extra#edit#CompleteSchema("", "", "")')

    expect(tables.split("\n")).to match_array ['foos', 'bars']
  end

  it "autocompletes schema tables from structure.sql" do
    touch_file 'db/structure.sql'
    write_file 'db/structure.sql', <<~EOF
      CREATE TABLE public.foos (
      );

      CREATE TABLE bars (
      );
    EOF

    edit_file 'test.rb'
    tables = vim.command('echo rails_extra#edit#CompleteSchema("", "", "")')

    expect(tables.split("\n")).to match_array ['foos', 'bars']
  end
end
