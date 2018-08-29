require "./crytok/*"

class CryTok
  # 记录每个token在输入中的位置
  struct Span
    @start : Int32
    @end : Int32
    @byte_start : Int32
    @byte_end : Int32
    property :start, :end, :byte_start, :byte_end

    def initialize(@start, @end, @byte_start, @byte_end)
    end

    def byte_size
      @byte_end - @byte_start
    end

    def size
      @end - @start
    end
  end
end
