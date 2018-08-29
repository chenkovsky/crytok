module Unicode
  def self.whitespace_chars : Array(Char)
    ret = [] of Char
    {% for name, idx in [:category_Zs, :category_Zl, :category_Zp] %}
    self.{{name.id}}.each do |low, high, stride|
      (low..high).step(stride) do |c|
        ret << c.unsafe_chr
      end
    end
    {% end %}
    return ret
  end
end

class CryTok
  @@whitespace_chars : Array(Char) = self.whitespace_chars
  @@is_whitespace = BitArray.new(@@whitespace_chars.max.ord + 1)
  @@whitespace_chars.each do |chr|
    @@is_whitespace[chr.ord] = true
  end

  def self.whitespace?(chr : Char)
    return false if chr.ord > @@is_whitespace.size
    return @@is_whitespace[chr.ord]
  end

  def self.whitespace_chars : Array(Char)
    Unicode.whitespace_chars
  end

  # split by white space
  protected def naive_split(text : String) : Void
    start_byte_offset = -1
    start_offset = -1
    current_byte_offset = 0
    current_offset = 0
    text.each_char_with_index do |chr, idx|
      current_offset = idx
      if self.class.whitespace? chr
        if start_offset != -1
          # 单词结束
          yield Span.new(start_offset, current_offset, start_byte_offset, current_byte_offset)
          start_offset = -1
        end
      else
        if start_offset == -1
          start_offset = current_offset
          start_byte_offset = current_byte_offset
        end
      end
      current_byte_offset += chr.bytesize
    end
    if start_offset != -1
      yield Span.new(start_offset, current_offset + 1, start_byte_offset, current_byte_offset)
    end
  end
end
