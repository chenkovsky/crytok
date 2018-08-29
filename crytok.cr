require "./src/crytok"
require "./src/langs/en"
tokenizer = CryTok.build_en
File.open(ARGV[0]) do |fi|
  File.open(ARGV[1], "w") do |fo|
    tokenizer.tokenized(fi, fo)
  end
end
