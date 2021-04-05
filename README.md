[![GitHub version](https://badge.fury.io/gh/andrewradev%2Frails_extra.vim.svg)](https://badge.fury.io/gh/andrewradev%2Frails_extra.vim)
[![Build Status](https://secure.travis-ci.org/AndrewRadev/rails_extra.vim.svg?branch=master)](http://travis-ci.org/AndrewRadev/rails_extra.vim)

## Dependencies

Depends on [vim-rails](https://github.com/tpope/vim-rails) -- please make sure that's installed first.

If **anything** in this plugin blocks a vim-rails feature or accidentally duplicates it (vim-rails is a large plugin), please let me know. See below on how you can selectively disable features if and when you need to.

Also consider taking a look at the "[Reliability](#reliability)" section for an idea on how well you can expect the plugin to work.

## Usage

The plugin defines some extra tools to work with Rails projects. Some of them might be a bit hacky, use heuristics, or support non-standard Rails tools, which might mean they don't necessarily make sense for vim-rails PRs.

Here's a demo of its upgrades to the `gf` family of mappings:

![Demo](http://i.andrewradev.com/75ff2a84fcdc79a487c725d42d571fbe.gif)

### Edit commands

There's extra editing commands (so far just one, `:Efactory`) you can use that are similar to what vim-rails provides. These are defined as buffer-local commands in rails project files, just like vim-rails does it. If you'd like to define them globally, see the "[Advanced Usage](#advanced-usage)" section below.

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

Where "Target" is one of the supported commands, currently only "Factory"

So, if you wanted to define global commands called `RailsEdit<Target>`, you could put this in your .vimrc:

``` vim
command! -nargs=* -complete=custom,rails_extra#edit#CompleteFactories
    \ RailsEditFactory call rails_extra#edit#Factory(<q-args>)
```

Defined like this, these kinds of commands should work just as well as the buffer-local ones, with completion and everything.

## Reliability

Part of the reason this plugin exists is simple [NIH](https://en.wikipedia.org/wiki/Not_invented_here) -- it's easier for me to work with my own code than to adjust to somebody else's style, especially when it comes to lots of small ad-hoc changes.

However, it's also possibly not "worth" including in vim-rails -- some features are hacky and/or potentially slow.

For example, `gf` on a route uses regexes to figure out the controller/action pair to jump to. This can never be 100% precise, since you can do stuff like `resource "#{variable}_foo"`, for example. But there's probably even static patterns that the plugin doesn't get. It *could* maybe run `rake routes` (fun fact: [vim-rails does that](https://twitter.com/tpope/status/1379167639914876929)). But figuring out what is under the cursor is a separate problem from getting the full route list.

Factory completion can also be potentially slow -- the plugin tries to read *all* the factory files, line by line, and collect factories by regex. It's never been slow for me, but it totally could be. If you use [vim-projectionist](https://github.com/tpope/vim-projectionist) with one file per factory, it would do the same job in a much more efficient way. But I often work with projects with multiple factories per file, and that's why this tool exists.

In the end, it's worked well enough for me in practice, with no catastrophic failures so far. The worst that has happened is that some `gf` on a route hasn't worked and I'd written it down to implement later and navigated to the right place manually, which is fine by me. Your mileage may vary -- please open a github issue if you hit a problem.

## Contributing

Pull requests are welcome, but take a look at [CONTRIBUTING.md](https://github.com/AndrewRadev/rails_extra.vim/blob/master/CONTRIBUTING.md) first for some guidelines. Be sure to abide by the [CODE_OF_CONDUCT.md](https://github.com/AndrewRadev/rails_extra.vim/blob/master/CODE_OF_CONDUCT.md) as well.
