require 'pry'
require 'dentaku'

PERF_SIZE = (ENV['PERF_SIZE'] || 5).to_i

# automatically create a token stream from bare values
def token_stream(*args)
  args.map.with_index do |value, index|
    type = type_for(value)
    Dentaku::Token.new(type, value, [index, index + 1])
  end
end

class Missing
  attr_reader :type
  def initialize(type)
    @type = type
  end
end

def missing(type)
  Missing.new(type)
end

class InputHash < Hash
  def [](key)
    out = super
    out = nil if out.is_a?(Missing)

    out
  end
end

def stringify_data(data={})
  if data.respond_to?(:stringify_keys)
    data.stringify_keys
  elsif data.respond_to?(:transform_keys)
    data.transform_keys(&:to_s)
  else
    data.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
  end
end

def input(data={})
  InputHash[stringify_data(data)]
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
