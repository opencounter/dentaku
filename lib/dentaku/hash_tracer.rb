module Dentaku
  class HashTracer
    attr_reader :satisfied
    attr_reader :unsatisfied

    def initialize
      @satisfied = Set.new
      @unsatisfied = Set.new
    end

    def trace(type, data)
      case type
      when :satisfied
        @satisfied << data
      when :unsatisfied
        @unsatisfied << data
      end
    end
  end
end
