module Dentaku
  class TracePoint
    attr_reader :children, :node

    def initialize(node)
      @node = node
      @children = []
    end

    def inspect
      "<TracePoint\n#{enum_for(:repr_lines).to_a.join("\n")}>"
    end

    def repr_lines(indent=0, &b)
      spaces = "  " * indent
      yield "#{spaces}#{node.repr}"

      children.each do |c|
        c.repr_lines(indent+1, &b)
      end
    end
  end

  class Tracer
    attr_reader :root
    attr_reader :runtime_dependencies

    def initialize
      @runtime_dependencies = []
    end

    def trace(node, &blk)
      parent, @last_point = @last_point, TracePoint.new(node)

      if parent
        parent.children << @last_point
      else
        @root = @last_point
      end

      result = yield

      case node
      when AST::Identifier, AST::Function
        @runtime_dependencies << [node, result]
      end

      result
    ensure
      @last_point = parent
    end
  end
end
