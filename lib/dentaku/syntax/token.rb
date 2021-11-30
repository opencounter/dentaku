module Dentaku
  class Token
    NEST = {
      :lbrack => :rbrack,
      :lbrace => :rbrace,
      :lparen => :rparen,
      :case   => :end,
    }

    CLAUSE = [:when, :then, :else]

    attr_reader :category, :value
    attr_accessor :original, :source_name, :loc_range

    def initialize(category, value)
      @category = category
      @value = value
    end

    def inspect
      "<Token :#{category}(#{value})@#{loc_range && loc_range.repr}>"
    end

    def source
      return nil unless @original && @loc_range
      @loc_range.slice(@original)
    end

    def begin
      @loc_range[0]
    end

    def end
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

    def nest?
      NEST.key?(category)
    end

    def nest_pair
      NEST[category]
    end

    def clause?
      CLAUSE.include?(category)
    end

    def eof?
      category == :eof
    end

    def checksum
      Zlib.crc32()
    end
  end
end
