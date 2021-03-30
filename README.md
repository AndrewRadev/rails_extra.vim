## Usage

Depends on [vim-rails](https://github.com/tpope/vim-rails) -- please make sure that's installed first.

The plugin defines some extra tools to work with Rails projects. Some of them might be a bit hacky, use heuristics, or support non-standard Rails tools, which might mean they don't necessarily make sense for vim-rails PRs.

### Edit commands

There are several extra editing commands you can use that are similar to what vim-rails provides. These are defined as buffer-local commands in rails project files, just like vim-rails does it. If you'd like to define them globally, see the "[Advanced Usage](#advanced-usage)" section below.

``` vim
:Eschema <table-name>
```

This will open the `schema.rb` file or the `structure.sql` file and attempt to jump to the given table name. It'll tab-complete said table names (for `structure.sql` in particular, this might not work well, because it depends on the specific database dump format -- PRs welcome for wider support).

``` vim
:Efactory <factory-name>
```

This will attempt to jump to a [`factory_bot`](https://github.com/thoughtbot/factory_bot) factory definition. You can use vim-projectionist for factories, but that approach will only pick out factories in separate files. This `:Efactory` command does some extra work to parse all the factory bot files for definitions -- this will mean it's slower, so your mileage might vary.

### Go to file

Vim-rails makes the `gf` family of mappings (`<c-w>f`, `<c-w>gf`, etc) extremely powerful, allowing you to `gf` from a model name into that model, jump through partials and a lot more. Rails-extra tries to add a few more tools to that mix.

Translations:

``` ruby
# gf will try to jump to that key in `config/locale/en.yml`:
t("foo.bar.baz")
```

Assets:

``` scss
# jump to the file in the asset pipeline
//= require 'some_file'

# jump to the SCSS import
@import "some_file"
```

Routes in `config/routes.rb` (doesn't work for everything, but a few examples):

``` ruby
resources :users

get 'route', to: 'users#profile'

controller :home do
  get '/example', :action => 'example_action'
end
```

Factory bot factories -- cursor on the factory name:

``` ruby
create :user, :admin, name: 'Example'

build_stubbed :product

attributes_for :post
```

Custom RSpec matchers -- cursor on the matcher:

``` ruby
# Would jump to: spec/support/matchers/wibble_and_wobble_matcher.rb
expect(timey_wimey_stuff).to wibble_and_wobble(42)
```


Expect these to not quite work at 100% all the time. There's lots of ways to configure and organize code, so the above examples make guesses based on my own experience. If you have a different setup, please open a github issue and describe your case -- I might be able to support it.

## Advanced Usage

If you'd like to be able to run the edit commands on empty buffers, you could define them globally. This means you'd be polluting the global namespace, causing problems if you have other kinds of project you'd like to work on.

This might make sense in 1) a project-specific file that only activates when you decide to "edit a project" -- it's what I do. Or, if you 2) name your global commands in a rails-specific way.

For each editing command defined by this plugin, there's going to be two functions that let it work:

``` vim
rails_extra#edit#<Target>
rails_extra#edit#Complete<Target>
```

Where "Target" is one of the supported commands, "Schema" or "Factory" for the moment.

So, if you wanted to define global commands called `RailsEdit<Target>`, you could put this in your .vimrc:

``` vim
command! -nargs=* -complete=custom,rails_extra#edit#CompleteSchema
    \ RailsEditSchema call rails_extra#edit#Schema(<q-args>)

command! -nargs=* -complete=custom,rails_extra#edit#CompleteFactories
    \ RailsEditFactory call rails_extra#edit#Factory(<q-args>)
```

These should work just as well as the buffer-local ones, with completion and everything.

## Contributing

Pull requests are welcome, but take a look at [CONTRIBUTING.md](https://github.com/AndrewRadev/rails_extra.vim/blob/master/CONTRIBUTING.md) first for some guidelines. Be sure to abide by the [CODE_OF_CONDUCT.md](https://github.com/AndrewRadev/rails_extra.vim/blob/master/CODE_OF_CONDUCT.md) as well.
