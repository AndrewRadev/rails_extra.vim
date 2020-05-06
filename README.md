## Usage

**TODO**

Depends on [vim-rails](https://github.com/tpope/vim-rails)

Commands (only in rails projects):

``` vim
:Eschema <table-name>
:Efactory <factory-name>
```

The `gf` mapping now works for:

- Translations (`t("foo.bar.baz")`)
- Assets (`= require`, `@import`)
- Routes in the router (not perfect, but works most of the time)
- Factories (cursor on `create`, `build` etc, only for separate factory files, needs more work)
- Custom rspec matchers

**TODO More explanations, fixes**

## Contributing

Pull requests are welcome, but take a look at [CONTRIBUTING.md](https://github.com/AndrewRadev/rails_extra.vim/blob/master/CONTRIBUTING.md) first for some guidelines. Be sure to abide by the [CODE_OF_CONDUCT.md](https://github.com/AndrewRadev/rails_extra.vim/blob/master/CODE_OF_CONDUCT.md) as well.
