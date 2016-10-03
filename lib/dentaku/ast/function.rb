require_relative 'node'

module Dentaku
  module AST
    class Function < Node
      attr_reader :args

      def initialize(*args)
        @args = args
      end

      def dependencies(context={})
        @args.flat_map { |a| a.dependencies(context) }
      end

      def self.normalize_name(name)
        name.to_s.downcase
      end

      def self.get(name)
        registry.fetch(normalize_name(name)) { fail "Undefined function #{ name } "}
      end

      def self.function_name
        normalize_name(type_spec.name)
      end

      def function_name
        self.class.function_name
      end

      def self.type_spec
        @type_spec ||= Type::Syntax.parse_spec(type_syntax)
      end

      def self.register(type_syntax, implementation)
        function = Class.new(self) do
          def value
            args = @args.map { |a| a.evaluate }
            self.class.implementation.call(*args)
          end

          singleton_class.class_eval do
            define_method(:type_syntax) { type_syntax }
            define_method(:implementation) { implementation }
          end
        end

        register_class(function)
      end

      def self.register_class(function_class)
        registry[function_class.function_name] = function_class
      end

      def type_spec
        self.class.type_spec
      end

      def self.type_syntax
        raise "Abstract #{self.class.name}"
      end

      def repr
        "#{function_name}(#{args.map(&:repr).join(', ')})"
      end

      def generate_constraints(context)
        @scope = {}
        context.add_constraint!([:syntax, self], type_spec.return_type.resolve_vars(@scope), [:retval, self])
        type_spec.arg_types.zip(args).each_with_index do |(type, arg), i|
          context.add_constraint!([:syntax, arg], type.resolve_vars(@scope), [:arg, self, i])
          arg.generate_constraints(context)
        end
      end

      private

      def self.registry
        @registry ||= {}
      end
    end
  end
end
