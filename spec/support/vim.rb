require 'fileutils'

module Support
  module Vim
    def touch_file(filename)
      write_file(filename, '')
    end

    def write_file(filename, string)
      if !File.exists?(filename)
        FileUtils.mkdir_p(File.dirname(filename))
      end

      string = normalize_string_indent(string)
      File.open(filename, 'w') { |f| f.write(string + "\n") }
    end

    def edit_file(filename, contents = nil)
      if contents
        write_file(filename, contents)
      else
        touch_file(filename)
      end

      vim.edit!(filename)
    end

    def current_file
      vim.command('echo expand("%:.")')
    end

    def current_line
      vim.command('echo getline(".")')
    end

    def expect_file_contents(filename, string)
      string = normalize_string_indent(string)
      expect(IO.read(filename).strip).to eq(string)
    end
  end
end
