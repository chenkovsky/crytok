require "aha"
require "./segmentor"

class CryTok
  {% for name, idx in [:prefix, :suffix, :infix, :special] %}
  @{{name.id}} : Segmentor
  {% end %}

  def initialize(@prefix, @suffix, @infix, @special)
  end

  def tokenize(text : String, hit_buff : Array(Span) = [] of Span, &block : Span -> Void) : Void
    naive_split(text) do |hit|
      split_affixes(text, hit, hit_buff) do |hit2|
        yield hit2
      end
    end
  end

  def tokens(text : String, hit_buff : Array(Span) = [] of Span, &block : String -> Void) : Void
    tokenize(text, hit_buff) do |hit|
      yield text.byte_slice(hit.byte_start, hit.byte_size)
    end
  end

  def tokens(text : String, hit_buff : Array(Span) = [] of Span) : Array(String)
    ret = [] of String
    tokens(text, hit_buff) do |tok|
      ret << tok
    end
    ret
  end

  def tokenized(text : String, fo : IO, hit_buff : Array(Span) = [] of Span)
    tokenize(text, hit_buff) do |span|
      fo.write_utf8 Bytes.new(text.to_unsafe + span.byte_start, span.byte_size)
      fo.write_byte ' '.ord.to_u8
    end
  end

  def tokenized(fi : IO, fo : IO, hit_buff : Array(Span) = [] of Span)
    fi.each_line do |l|
      tokenized(l, fo, hit_buff)
      fo.write_byte '\n'.ord.to_u8
    end
  end

  protected def segment_prefix_suffix(text : String,
                                      whole_span : Span*,
                                      search_span : Span*,
                                      hit_buff : Array(Span) = [] of Span,
                                      &block : Span -> Void) : Bool
    prefix_matched = true
    suffix_matched = true
    post_recut = true
    prev_recut = true
    while prefix_matched || suffix_matched
      # STDERR.puts "matching: whole_span: #{text.byte_slice(whole_span.value.byte_start, whole_span.value.byte_size).inspect}, #{text.byte_slice(search_span.value.byte_start, search_span.value.byte_size).inspect}"
      {% for names, idx in [{:prefix, :post}, {:suffix, :prev}] %}
      special_matched = @special.segment(text, whole_span, search_span, pointerof(post_recut)) do |span, _|
        yield span
      end
      return false if special_matched
      if {{names[0].id}}_matched
        {{names[0].id}}_matched = @{{names[0].id}}.segment(text, whole_span, search_span, pointerof({{names[1].id}}_recut)) do |span, _|
          # STDERR.puts "#{{{names[0]}}}: #{text.byte_slice(span.byte_start, span.byte_size).inspect}"
          {% if names[0] == :prefix %}
            yield span
          {% else %}
            hit_buff << span
          {% end %}
        end
      end
      return false unless {{names[1].id}}_recut
      {% end %}
    end
    return true
  end

  def split_affixes(text : String, hit : Span, hit_buff : Array(Span) = [] of Span, &block : Span -> Void) : Void
    search_span = hit
    whole_span = search_span
    hit_buff.clear
    rest_cut = segment_prefix_suffix(text, pointerof(whole_span), pointerof(search_span), hit_buff) do |span|
      yield span
    end
    while rest_cut
      infix_matched = @infix.segment(text, pointerof(whole_span), pointerof(search_span), pointerof(rest_cut)) do |span, cur_recut|
        if cur_recut
          search_span2 = span
          whole_span2 = span
          hit_buff_offset = hit_buff.size
          segment_prefix_suffix(text, pointerof(whole_span2), pointerof(search_span2), hit_buff) do |span2|
            yield span2
          end
          if whole_span2.start < whole_span2.end
            yield whole_span2
          end
          (hit_buff_offset...hit_buff.size).reverse_each do |i|
            yield hit_buff[i]
          end
          hit_buff.pop(hit_buff.size - hit_buff_offset)
        else
          yield span
        end
      end
      break unless infix_matched
    end
    if whole_span.start < whole_span.end
      yield whole_span
    end
    hit_buff.reverse_each do |hit|
      yield hit
    end
  end
end
