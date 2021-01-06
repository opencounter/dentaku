require 'dentaku/ast/function'

module Dentaku
  module AST
    class UndefinedFunctionMaker
      def initialize(name)
        @name = name
      end

      # yes this is an instance method
      def new
      end
    end

    # function class for handling undefined functions. will result in type
    # errors later.
    class UndefinedFunction < Function
      class Factory
        # using a factory here in order to not bust the global ruby cache by
        # creating a new class post-load-time. an instance of this should operate
        # more or less like a sub*class* of Dentaku::AST::Function.

        attr_reader :function_name
        def initialize(name)
          @function_name = name
        end

        # skip arity-checking in the parser - this is already an error state
        def arity
          nil
        end

        # hack to make this look like a subclass of Function
        def <=(klass)
          UndefinedFunction <= klass
        end

        def new(*args)
          UndefinedFunction.new(@function_name, args)
        end
      end

      def self.named(func_name)
        Factory.new(func_name)
      end

      attr_reader :function_name, :args
      def initialize(name, args)
        @function_name = name
        @args = args
      end

      def arity
        @args.size
      end

      def generate_constraints(context)
        # we don't actually generate constraints here, since nothing is known
        # about the function - instead we merely inform the checker that this
        # function is unknown, which will result in a type error down the line.
        # importantly, though, we allow the checker to continue checking the
        # rest of the expression to find any other type or variable errors that
        # may exist.
        context.undefined_function!(self)

        # we do want to check the arguments though, so let's continue to recurse
        # down the tree.
        @args.each { |a| a.generate_constraints(context) }
      end
    end
  end
end
