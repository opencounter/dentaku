
require 'spec_helper'
require 'dentaku/calculator'

class DefaultValue
  attr_reader :value
  def initialize(value)
    @value = value
  end
end

def defaulted(value)
  DefaultValue.new(value)
end

class InputHash < Hash
  attr_accessor :with_defaults

  def [](key)
    out = super

    if out.is_a?(DefaultValue)
      if with_defaults
        return [out.value, :default]
      else
        out = nil
      end
    end

    [out, :user]
  end

  def with_default(defaults_flag)
    self.with_defaults = defaults_flag
    yield
  ensure
    self.with_defaults = !defaults_flag
  end
end

describe Dentaku::Calculator do
  let(:calculator)  do
    Dentaku::Calculator.new.tap do |c|
      c.cache = {}
    end
  end

  def eval_expressions(expressions_with_default_flag, vars)
    inp = input(vars)
    calculator.with_input(inp) do |c|
      expressions_with_default_flag.map do |e, use_defaults|
        defaults_flag = use_defaults == :with_defaults ? true : false
 
        c.current_node_cache = nil # Copy hack from OC

        inp.with_default(defaults_flag) do
          puts eval: e, with: defaults_flag
          res = c.ast(e).evaluate
          puts res: res
          res
        end
      end
    end
  end

  context "fixed branch favoring is not caching" do
    let(:expression_1) do
      <<-E
        a or ((b or c) or not(d))
      E
    end

    let(:expression_2) do
      <<-E
        (b or c) or (d and e)
      E
    end

    # This reproduces an existing bug where we don't take
    # allow_defaults into consideration when caching nodes
    #
    # If an expression without allow_defaults is executed after
    # one with that shares any cached nodes then the second
    # expression will return the cached value as if allow
    # defaults were stil on
    #
    # Unfortunately config is relying upon the behavior of this bug
    # so we cant fix it until we run an allow_defaults migration
    # that wraps expressions in defaults that were executing
    # as if they had allow_defaults because of this bug
    #
    # with fixed branch favoring....
    # in expression_1(defaults) (b or c) is not cached
    # so expression_2(nodefaults) fails as would be expected since there isn't a value for b
    #
    # in master (b or c) is cached from expression_1 as true using defaults values
    # so expression_2 gets the cached value and returns true
    it "shouldn't change behavior" do
      results = eval_expressions({
        expression_1 => :with_defaults,
        expression_2 => :without_defaults,
      }, { a: false, b: defaulted(true), d: false, e: false })

      expect(results.all? { |r| r == true }).to be true
    end
  end
end
