class CryTok
  def self.char_num(text : String, byte_start : Int32, byte_end : Int32)
    reader = Char::Reader.new(text, byte_start)
    ret = 0
    # STDERR.puts "index: #{index}, reader.pos: #{reader.pos}"
    while reader.pos < byte_end && reader.has_next?
      ret += 1
      reader.next_char
    end
    return ret
  end
end
