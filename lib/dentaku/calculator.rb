require 'oj'
require 'zlib'

require "dentaku/type/variant"
require "dentaku/type/error"
require 'dentaku/type/checker'
require 'dentaku/type/constraint'
require 'dentaku/type/reason'
require 'dentaku/type/solution_set'
require 'dentaku/type/solver'
require 'dentaku/type/type'
require 'dentaku/type/syntax'
require 'dentaku/type/expression'
require "dentaku/type/declared"

require 'dentaku/hash_tracer'

require 'dentaku'
require 'dentaku/exceptions'
require 'dentaku/dependency_resolver'
require 'dentaku/ast'
require 'dentaku/syntax'

module Dentaku
  class Calculator
    attr_reader :result, :tokenizer, :cache, :current_node_cache
    attr_accessor :memory
    attr_writer :current_node_cache
    attr_accessor :tracer

    def initialize(ast_cache={})
      @memory = {}
      # @tokenizer = Tokenizer.new
      @ast_cache = ast_cache
      @partial_eval_depth = 0
    end

    THREAD_KEY = :dentaku_current_calculator
    def with_dynamic
      Thread.current[THREAD_KEY], old = self, Thread.current[THREAD_KEY]
      yield
    ensure
      Thread.current[THREAD_KEY] = old
    end

    def self.current
      Thread.current[THREAD_KEY] or raise "no calculator defined, use evaluate"
    end

    def add_function(type, body)
      Dentaku::AST::Function.register(type, body)
      self
    end

    def add_functions(fns)
      fns.each { |(type, body)| add_function(type, body) }
      self
    end

    def evaluate(expression, data={})
      evaluate!(expression, data)
    rescue UnboundVariableError
      yield expression if block_given?
    end

    # [jneen] because with_partial { ... } blocks can nest, we can't
    # simply use a boolean here - it would reset the state too early.
    # a counter is an easy way to allow nesting.
    def with_partial
      @partial_eval_depth += 1
      yield
    ensure
      @partial_eval_depth -= 1
    end

    def partial_eval?
      @partial_eval_depth > 0
    end

    def evaluate!(expression, data={})
      with_input(data) do
        if expression.is_a?(Dentaku::AST::Node)
          expression.evaluate
        else
          ast(expression).evaluate
        end
      end
    end

    def dependencies(expression)
      ast(expression).dependencies(memory)
    end

    def ast(expression)
      return expression if expression.is_a?(AST::Node)

      Syntax.parse(expression).tap do |node|
        @ast_cache[expression] = node
      end
    end

    def empty?
      memory.empty?
    end

    def trace(type, data)
      return if tracer.nil?
      tracer.trace(type, data)
    end

    def with_input(input)
      @memory, old_memory = input, @memory
      with_dynamic { yield }
    ensure
      @memory = old_memory
    end
  end
end
