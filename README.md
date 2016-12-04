# Codenize

Generate scaffold for Codenize.tools.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'codenize'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install codenize

## Usage

```sh
codenize -n hello
cd hello
sed -i.bak 's/TODO://' hello.gemspec
sed -i.bak 's/spec.homepage/#spec.homepage/' hello.gemspec
bundle exec ./exe/hello export hello.rb
bundle exec ./exe/hello apply hello.rb
```

## Example implementation

- https://github.com/winebarrel/ecman/commit/941555eee0ca59894efc9b3b3b52e8e66b5a63fa


## Related links

- [Codenize.tools](https://codenize.tools/)
