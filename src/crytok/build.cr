class CryTok
  def self.build
    bd = Builder.new
    with bd yield
    CryTok.new(bd.create_prefix, bd.create_suffix, bd.create_infix, bd.create_special)
  end

  class Builder
    {% for name, idx in [:prefix, :suffix, :infix, :special] %}
    @{{name.id}} : Aha::Cedar = Aha::Cedar.new
    @{{name.id}}_seg_offsets : Array(Int32) = [0] of Int32
    @{{name.id}}_segs : Array(Cut) = [] of Cut

    def {{name.id}}(pat : String, segs : Array(Cut)) : Int32
      id = @{{name.id}}.insert pat
      raise "pat:#{pat.inspect} insert twice" if id + 1 > @{{name.id}}_seg_offsets.size
      @{{name.id}}_segs.concat segs
      @{{name.id}}_seg_offsets << @{{name.id}}_segs.size
      id
    end

    def split_{{name.id}}(pat : String) : Int32
      {% if name == :suffix %}
      pat = pat.reverse
      {% end %}
      left_seg = Cut.new(0, true)
      right_seg = Cut.new(pat.bytesize, true)
      segs = [left_seg, right_seg]
      {{name.id}}(pat, segs)
    end

    def no_split_{{name.id}}(pat : String) : Int32
      raise "pat.size should >= 2" unless pat.size >= 2
      segs = [Cut.new(pat.bytesize, false)]
      {{name.id}}(pat, segs)
    end

    protected def create_{{name.id}}
      return Segmentor::{{name.capitalize.id}}.new(@{{name.id}}, @{{name.id}}_seg_offsets, @{{name.id}}_segs)
    end
    {% end %}
  end
end
