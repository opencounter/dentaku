module Dentaku
  class RuntimeContext
    def self.with_runtime_context(&blk)
      instance = exists? ? new(current.scope.dup) : new({})
      Thread.current[:dentaku_runtime_context], old = instance, Thread.current[:dentaku_runtime_context]
      begin
        yield
      ensure
        Thread.current[:dentaku_runtime_context] = old
      end
    end

    def self.exists?
      !!Thread.current[:dentaku_runtime_context]
    end

    def self.current
      Thread.current[:dentaku_runtime_context] or raise RuntimeError, "No runtime context set"
    end

    def initialize(scope)
      @scope = scope
      @runtime_dependencies = []
    end

    def [](key)
      @scope[key.to_s.downcase]
    end

    def merge!(hash)
      hash.each { |k, v| self[k] = v }
    end

    def each(&b)
      @scope.each(&b)
    end

    def has_key?(key)
      @scope.has_key?(key.to_s.downcase)
    end

    def []=(key, val)
      @scope[key.to_s.downcase] = val
    end
  end
end
