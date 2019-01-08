module Dentaku
  class Token
    attr_reader :category, :index_range, :loc_range, :raw_value, :value

    def initialize(category, value, index_range=nil, loc_range=nil, raw_value=nil)
      if raw_value.nil?
        raw_value = loc_range
      end

      @category  = category
      @value     = value
      @index_range = index_range
      @loc_range = loc_range
      @raw_value = raw_value
    end

    def inspect
      "<Token :#{category}/#{value}#{loc_range && loc_range.inspect} #{raw_value}>"
    end

    def begin_location
      @loc_range[0]
    end

    def end_location
      @loc_range[1]
    end

    def to_s
      raw_value || value
    end

    def length
      raw_value.to_s.length
    end

    def grouping?
      is?(:grouping)
    end

    def is?(c)
      category == c
    end

    def ==(other)
      (category.nil? || other.category.nil? || category == other.category) &&
      (value.nil?    || other.value.nil?    || value    == other.value)
    end

    def checksum
      Zlib.crc32()
    end
  end
end
