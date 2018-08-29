# crytok

Fastest configurable Indo European Language Tokenizer on earth based on double array trie & ac automata.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crytok:
    github: your-github-user/crytok
```

## Usage

```crystal
require "crytok"
require "crytok/langs/en"
tokenizer = CryTok.build_en # a simple english tokenizer
# if you want to change the tokenize rule, look the implementation of 'build_en'

File.open(ARGV[0]) do |fi|
  File.open(ARGV[1], "w") do |fo|
    tokenizer.tokenized(fi, fo)
  end
end

```


## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/chenkovsky/crytok/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [chenkovsky](https://github.com/chenkovsky) chenkovsky - creator, maintainer
