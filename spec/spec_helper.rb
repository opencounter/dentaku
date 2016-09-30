require 'pry'
require 'dentaku'

# automatically create a token stream from bare values
def token_stream(*args)
  args.map.with_index do |value, index|
    type = type_for(value)
    Dentaku::Token.new(type, value, [index, index + 1])
  end
end

# make a (hopefully intelligent) guess about type
def type_for(value)
  case value
  when Numeric
    :numeric
  when String
    :string
  when true, false
    :logical
  when :add, :subtract, :multiply, :divide, :mod, :pow
    :operator
  when :open, :close, :comma
    :grouping
  when :le, :ge, :ne, :ne, :lt, :gt, :eq
    :comparator
  when :and, :or
    :combinator
  when :if, :round, :roundup, :rounddown, :not
    :function
  else
    :identifier
  end
end
