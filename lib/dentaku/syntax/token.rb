module Dentaku
  class Token
    NEST = {
      :lbrack => :rbrack,
      :lbrace => :rbrace,
      :lparen => :rparen,
      :case   => :end,
    }

    CLOSE = Set.new(NEST.values)

    CLAUSE = Set.new %i( when then else )

    DESC = {
      :lparen => 'parenthesis',
      :rparen => 'parenthesis',
      :lbrack => 'square bracket',
      :rbrack => 'square bracket',
      :lbrace => 'curly brace',
      :rbrace => 'curly brace',
      :case => 'CASE keyword',
      :end => 'END keyword',
    }

    def desc
      DESC.fetch(category) { category.to_s }
    end

    attr_reader :category, :value
    attr_accessor :original, :source_name, :loc_range

    def initialize(category, value)
      @category = category
      @value = value
    end

    def inspect
      "<Token :#{category}(#{value})#{loc_range && loc_range.repr}>"
    end

    def repr
      if @value
        "#{category.inspect}(#{@value.inspect})#{loc_range && loc_range.repr}"
      else
        "#{category.inspect}#{loc_range && loc_range.repr}"
      end
    end

    def source
      return nil unless @original && @loc_range
      @loc_range.slice(@original)
    end

    def as_json(*)
      {
        token: category,
        value: value,
        location: loc_range.as_json
      }
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
      @category == other.category && @value == other.value
    end

    def nest?
      NEST.key?(category)
    end

    def close?
      CLOSE.include?(category)
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
  end
end
