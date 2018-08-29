class CryTok
  struct Cut
    @val : UInt32

    def initialize(val : Int, cut : Bool, prev_recut : Bool = true, post_recut : Bool = true)
      @val = val.to_u32
      self.cut = cut
      self.prev_recut = prev_recut
      self.post_recut = post_recut
    end

    FLAGS = [:cut, :prev_recut, :post_recut]
    {% for name, idx in FLAGS %}
      def {{name.id}}?
        @val & (1 << {{31 - idx}}) != 0
      end

      def {{name.id}}=(v : Bool)
        @val |= (1 << {{31 - idx}})
      end
      {% end %}

    VAL_MASK = (1 << (32 - FLAGS.size)) - 1

    def pos : Int32
      (@val & VAL_MASK).to_i32
    end
  end

  abstract class Segmentor
    #  如果匹配到了，那么修改whole_span和search_span并且返回true
    abstract def segment(text : String,
                         whole_span : Span*,
                         search_span : Span*,
                         seg_rest : Bool*, # 剩余的是否还需要切分，默认需要切分
                         &block : Span, Bool -> Void) : Bool

    # block 的第二个参数表示是否需要对这个区块重新切割, 仅对infix切分出来的有用

    abstract class Affix < Segmentor
      @seg_offsets : Array(Int32)
      @segs : Array(Cut)
      @forward : Bool
      protected getter :seg_offsets, :segs

      def initialize(@seg_offsets, @segs, @forward)
      end

      abstract def find(text : String, whole_span : Span, search_span : Span, hit_span : Span*, rule_id : Int32*) : Bool

      def segment(text : String, whole_span : Span*, search_span : Span*, seg_rest : Bool*, &block : Span, Bool -> Void) : Bool
        hit_span = search_span.value
        rule_id = -1
        return false unless find(text, whole_span.value, search_span.value, pointerof(hit_span), pointerof(rule_id))
        if @forward
          # 从前往后切分
          seg_rest.value = forward(text, whole_span, search_span, pointerof(hit_span), rule_id) do |span, reseg|
            yield span, reseg
          end
        else
          # 从后往前切分
          seg_rest.value = backward(text, whole_span, search_span, pointerof(hit_span), rule_id) do |span, reseg|
            yield span, reseg
          end
        end
        return true
      end

      # search_span 是搜索的时候的byte_start
      protected def forward(text : String, whole_span : Span*, search_span : Span*, hit_span : Span*, rule_id : Int32, &block : Span, Bool -> Void) : Bool
        seg_rest = true
        (@seg_offsets[rule_id]...@seg_offsets[rule_id + 1]).each do |v|
          seg = segs[v]
          seg_offset = hit_span.value.byte_start + seg.pos
          if seg.cut? && seg_offset > whole_span.value.byte_start
            chr_num = CryTok.char_num(text, whole_span.value.byte_start, seg_offset)
            yield Span.new(whole_span.value.start, whole_span.value.start + chr_num, whole_span.value.byte_start, seg_offset), seg.prev_recut?
            whole_span.value.byte_start = seg_offset
            whole_span.value.start = whole_span.value.start + chr_num
          end
          search_span.value.start = seg.cut? ? whole_span.value.start : (search_span.value.start + CryTok.char_num(text, search_span.value.byte_start, seg_offset))
          search_span.value.byte_start = seg_offset
          seg_rest = seg.post_recut?
        end
        return seg_rest
      end

      protected def backward(text : String, whole_span : Span*, search_span : Span*, hit_span : Span*, rule_id : Int32, &block : Span, Bool -> Void) : Bool
        seg_rest = true
        (@seg_offsets[rule_id]...@seg_offsets[rule_id + 1]).reverse_each do |v|
          seg = segs[v]
          seg_offset = hit_span.value.byte_start + seg.pos
          if seg.cut? && seg_offset < whole_span.value.byte_end
            chr_num = CryTok.char_num(text, seg_offset, whole_span.value.byte_end)
            yield Span.new(whole_span.value.end - chr_num, whole_span.value.end, seg_offset, whole_span.value.byte_end), seg.post_recut?
            whole_span.value.byte_end = seg_offset
            whole_span.value.end = whole_span.value.end - chr_num
          end
          search_span.value.end = seg.cut? ? whole_span.value.end : (search_span.value.end - CryTok.char_num(text, seg_offset, search_span.value.byte_end))
          search_span.value.byte_end = seg_offset
          seg_rest = seg.post_recut?
        end
        return seg_rest
      end
    end

    class Special < Affix
      @trie : Aha::Cedar

      def initialize(@trie, seg_offsets, segs)
        super(seg_offsets, segs, true)
      end

      def find(text : String, whole_span : Span, search_span : Span, hit_span : Span*, rule_id : Int32*) : Bool
        return false if search_span.byte_size == 0
        key = Bytes.new(text.to_unsafe + whole_span.start, whole_span.byte_size)
        v = @trie[key]?
        return false if v.nil?
        rule_id.value = v
        hit_span.value = whole_span
        return true
      end
    end

    class Infix < Affix
      @ac : Aha::AC

      def initialize(trie : Aha::Cedar, seg_offsets, segs)
        @ac = Aha::AC.compile trie
        super(seg_offsets, segs, true)
      end

      def find(text : String, whole_span : Span, search_span : Span, hit_span : Span*, rule_id : Int32*) : Bool
        return false if search_span.byte_size == 0
        bytes = Bytes.new(text.to_unsafe + search_span.byte_start, search_span.byte_end - search_span.byte_start)
        @ac.match_longest(bytes, true) do |hit|
          hit_span.value.byte_start = search_span.start + hit.start
          hit_span.value.byte_end = search_span.start + hit.end
          hit_span.value.start = search_span.start + CryTok.char_num(text, search_span.start, hit_span.value.byte_start)
          hit_span.value.end = hit_span.value.start + CryTok.char_num(text, hit.start, hit.end)
          rule_id.value = hit.value
          return true
        end
        return false
      end
    end

    class Prefix < Affix
      @trie : Aha::Cedar

      def initialize(@trie : Aha::Cedar, seg_offsets, segs)
        super(seg_offsets, segs, true)
      end

      def find(text : String, whole_span : Span, search_span : Span, hit_span : Span*, rule_id : Int32*) : Bool
        return false if search_span.byte_size == 0
        bytes = Bytes.new(text.to_unsafe + search_span.byte_start, search_span.byte_end - search_span.byte_start)
        last_vk, last_byte_num = 0, 0
        @trie.prefix(bytes) do |vk, byte_num|
          last_vk, last_byte_num = vk, byte_num if byte_num > last_byte_num
        end
        return false if last_byte_num == 0
        hit_span.value.byte_start = search_span.byte_start
        hit_span.value.byte_end = search_span.byte_start + last_byte_num
        hit_span.value.start = search_span.start
        hit_span.value.end = hit_span.value.start + CryTok.char_num(text, hit_span.value.byte_start, hit_span.value.byte_end)
        rule_id.value = last_vk
        return true
      end
    end

    class Suffix < Affix
      @trie : Aha::Cedar

      def initialize(@trie : Aha::Cedar, seg_offsets, segs)
        super(seg_offsets, segs, false)
      end

      def find(text : String, whole_span : Span, search_span : Span, hit_span : Span*, rule_id : Int32*) : Bool
        return false if search_span.byte_size == 0
        bytes = Bytes.new(text.to_unsafe + search_span.byte_start, search_span.byte_end - search_span.byte_start)
        last_vk, last_byte_num = 0, 0
        @trie.reverse_suffix(bytes) do |vk, byte_num|
          last_vk, last_byte_num = vk, byte_num if byte_num > last_byte_num
        end
        return false if last_byte_num == 0
        hit_span.value.byte_start = search_span.byte_end - last_byte_num
        hit_span.value.byte_end = search_span.byte_end
        hit_span.value.end = search_span.end
        hit_span.value.start = hit_span.value.end - CryTok.char_num(text, hit_span.value.byte_start, hit_span.value.byte_end)
        rule_id.value = last_vk
        return true
      end
    end
  end
end
