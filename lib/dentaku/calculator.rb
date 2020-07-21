require 'oj'
require 'zlib'

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
require 'dentaku/exceptions'
require 'dentaku/token'
require 'dentaku/tokenizer'
require 'dentaku/dependency_resolver'
require 'dentaku/parser'

module Dentaku
  class Calculator
    attr_reader :result, :memory, :tokenizer, :cache, :current_node_cache
    attr_writer :current_node_cache

    def initialize(ast_cache={})
      @memory = {}
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

    def with_input(data)
      @current_node_cache = nil

      with_dynamic do
        store(data) do
          yield self
        end
      end
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

    def trace(node, &blk)
      return yield if @tracer.nil?

      @tracer.trace(node, &blk)
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

    def cache
      @cache# ||= TraceCache.new({})
    end

    def cache=(execution_cache)
      @cache = TraceCache.new(execution_cache)
    end

    def cache_for(node)
      if block_given?
        previous_cache = @current_node_cache || cache

        begin
          @current_node_cache = cache.for(node)
          yield @current_node_cache
        ensure
          if previous_cache && previous_cache.node
            @current_node_cache = previous_cache.merge!(@current_node_cache.target)
          end
        end
      else
        cache.for(node)
      end
    end

    class TraceCache
      attr_reader :node

      def initialize(ast_storage={}, node=nil)
        @ast_storage = ast_storage || {}
        @node = node
      end

      def key
        node.checksum.to_s
      end

      def for(next_node)
        self.class.new(@ast_storage, next_node)
      end

      def merge!(child_cache)
        if target && target["unsatisfied_identifiers"]
          target["satisfied_identifiers"].to_set.merge(child_cache["satisfied_identifiers"] || [])
          target["unsatisfied_identifiers"].to_set.merge(child_cache["unsatisfied_identifiers"] || [])
        end
        self
      end

      def target
        @ast_storage[key] ||= {}
      end

      def dependencies
        @dependencies ||= Calculator.current.memory || {}
      end

      def getset
        raise RuntimeError unless @node
        keys = node.dependencies
        node_dependencies = Hash[[keys, dependencies.values_at(*keys)].transpose]

        node_input = node_dependencies.sort.each_with_object({}) do |(key, val), memo|
          memo[key] = if val.respond_to?(:stored_values)
            val.stored_values
          elsif val.is_a?(Array)
            val.map { |v| v.respond_to?(:stored_values) ? v.stored_values : v }
          else
            val
          end
        end
        json = Oj.dump(node_input)
        input_checksum = Zlib.crc32(json)

        if target && (target["input_checksum"] == input_checksum) && !target["value"].nil?
          if target['value'].nil?
            raise UnboundVariableError.new(target["unsatisfied_identifiers"])
          else
            target["value"]
          end
        else
          target["node_type"] = node.class.to_s
          target["input_checksum"] = input_checksum
          target["unsatisfied_identifiers"] = Set.new
          target["satisfied_identifiers"] = Set.new
          target.delete("value")

          target["value"] = yield
        end
      end

      def trace
        target["unsatisfied_identifiers"] = Set.new
        target["satisfied_identifiers"] = Set.new

        yield Tracer.new(target)
      end

      def dump
        Marshal.dump(@ast_storage)
      end

      def unsatisfied_identifiers
        @ast_storage.values.map do |v|
          v["unsatisfied_identifiers"]
        end.inject(&:+)
      end

      def satisfied_identifiers
        @ast_storage.values.map do |v|
          v["satisfied_identifiers"]
        end.inject(&:+)
      end

      class Tracer
        def initialize(cache)
          @cache = cache
        end

        def satisfied(key)
          @cache["satisfied_identifiers"] << key
        end

        def unsatisfied(key)
          @cache["unsatisfied_identifiers"] << key
        end
      end
    end

    def empty?
      memory.empty?
    end

    private

    def store(key_or_hash)
      @memory = key_or_hash || {}

      if block_given?
        begin
          return yield
        ensure
          @memory = {}
        end
      end

      self
    end
    alias_method :bind, :store

  end
end
