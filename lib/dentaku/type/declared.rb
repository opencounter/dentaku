module Dentaku
  module Type
    DECLARED_TYPES = {}
    def self.declare(name, arity=0, &b)
      name = name.to_sym

      raise "multiple declarations of #{name}" if DECLARED_TYPES.key?(name)
      decl = DECLARED_TYPES[name] = Class.new(DeclaredType) do
        singleton_class.class_eval do
          define_method(:arity) { arity }
          define_method(:type_name) { name }
        end

        b && class_eval(&b)
      end

      Type.singleton_class.define_method(name) { |*a| Type.declared(decl.new(a)) }
    end

    class DeclaredType
      def self.arity; raise "abstract"; end
      def arity; self.class.arity; end

      def self.type_name; raise "abstract"; end
      def type_name; self.class.type_name; end

      attr_reader :args
      def initialize(args)
        @args = args

        check_arity!
      end

      def check_arity!
        unless @args.size == arity
          raise "wrong number of type args for #{type_name} (expected #{arity}, got #{@args.size})"
        end
      end

      def repr
        return ":#{type_name}" if args.empty?
        ":#{type_name}(#{args.map(&:repr)})"
      end

      def inspect
        "(declared #{repr})"
      end

      def to_sexpr
        [type_name, *@args.map(&:to_sexpr)]
      end
    end

    declare(:bool)
    declare(:numeric)
    declare(:string)
    declare(:range)
    declare(:list, 1) do
      def repr
        "[#{args[0].repr}]"
      end
    end

    declare(:pair, 2)

    declare(:lambda, -1) do
      # override
      def check_arity!
        if @args.size < 2
          raise "wrong number of arguments for lambda (must be > 2, got #{args.size})"
        end
      end

      def repr
        "\\#{@args[1..].map(&:repr).join(' ')} => #{args[0].repr}"
      end
    end


  end
end
