require "dentaku/type/variant"
require 'dentaku/type/checker'
require 'dentaku/type/constraint'
require 'dentaku/type/reason'
require 'dentaku/type/solution_set'
require 'dentaku/type/solver'
require 'dentaku/type/type'
require 'dentaku/type/syntax'
require 'dentaku/type/expression'

require 'dentaku/tracer'

require 'dentaku'
require 'dentaku/bulk_expression_solver'
require 'dentaku/exceptions'
require 'dentaku/token'
require 'dentaku/dependency_resolver'
require 'dentaku/parser'

module Dentaku
  class Calculator
    attr_reader :result, :memory, :tokenizer, :previous_run_cache

    def initialize(ast_cache={})
      clear
      # @tokenizer = Tokenizer.new
      @ast_cache = ast_cache
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

    def evaluate_with_trace(expression, data={})
      @tracer = Tracer.new
      [evaluate!(expression, data), @tracer]
    end

    def evaluate!(expression, data={})
      with_dynamic do
        store(data) do
          node = expression
          node = ast(node) unless node.is_a?(AST::Node)
          node.evaluate
        end
      end
    end

    def trace(node, &blk)
      return yield if @tracer.nil?

      @tracer.trace(node, &blk)
    end

    def solve!(expression_hash)
      BulkExpressionSolver.new(expression_hash, self).solve!
    end

    def solve(expression_hash, &block)
      BulkExpressionSolver.new(expression_hash, self).solve(&block)
    end

    def dependencies(expression)
      ast(expression).dependencies(memory)
    end

    def ast(expression)
      @ast_cache.fetch(expression) {
        Parser.new(Tokenizer.tokenize(expression)).parse.tap do |node|
          @ast_cache[expression] = node if Dentaku.cache_ast?
        end
      }
    end

    def store(key_or_hash, value=nil)
      restore = Hash[memory]

      if value.nil?
        key_or_hash.each do |key, val|
          memory[key.to_s.downcase] = val
        end
      else
        memory[key_or_hash.to_s.downcase] = value
      end

      if block_given?
        begin
          return yield
        ensure
          @memory = restore
        end
      end

      self
    end
    alias_method :bind, :store

    def store_formula(key, formula)
      store(key, ast(formula))
    end

    def cache
      @cache ||= Cache.new({})
      yield @cache
    end

    class Cache
      def initialize(ast_storage={}, input={}, context=nil)
        @ast_storage = ast_storage || {}
        @input = input
        @context = context
      end

      def with(node)

      end

      def getset(node, dependencies)
        key = node.checksum
        cached = @ast_storage[key]

        node_deps = dependencies.slice(*node.dependencies).map(&:first)
        input_checksum = Zlib.crc32(node_deps.sort.to_json)

        if cached && cached[:input_checksum] == input_checksum
          puts :got_cached_value
          cached[:value]
        else
          @ast_storage[key] ||= {}
          @ast_storage[key][:node_type] = node.class.to_s
          @ast_storage[key][:input_checksum] = input_checksum


          # should somehow track visited nodes of children
          @ast_storage[key][:value] = yield Tracer.new(@ast_storage[key])
        end
      end

      class Tracer
        def initialize(cache)
          @cache = cache
        end

        def satisfied(key)
          (@cache[:satisfied_identifiers] ||= []) << key
        end

        def unsatisfied(key)
          (@cache[:unsatisfied_identifiers] ||= []) << key
        end
      end
    end

    def clear
      @memory = {}
      @cache = nil
    end

    def empty?
      memory.empty?
    end
  end
end
