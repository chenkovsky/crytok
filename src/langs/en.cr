require "../crytok"

class CryTok
  def self.build_en : CryTok
    self.build do
      ["'", ".", "?", "!", "\""].each do |s|
        split_infix(s)
      end
      ["'s", "'ll", "'re", "'m", "'d"].each do |s|
        split_suffix(s)
      end
    end
  end
end
