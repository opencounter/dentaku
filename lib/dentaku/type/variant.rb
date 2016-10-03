module Dentaku
  module Type
    class Variant
      def self.variants(cases={})
        cases.each do |name, members|
          parent_class = self

          klass = Class.new(parent_class) do
            define_method(:initialize) do |values|
              raise ArgumentError unless values.length == members.length
              members.zip(values) do |name, value|
                instance_variable_set("@#{name}", value)
              end
              instance_variable_set("@_values", values)
            end

            define_method(:_name) { name }
            define_method(:_variant) { parent_class.name }
            define_method("#{name}?") { true }

            attr_reader *members
          end

          define_method("#{name}?") { false }

          self.singleton_class.class_eval do
            define_method(name) do |*values|
              klass.new(values)
            end
          end
        end
      end

      def cases(clauses={})
        if clauses.key?(self._name)
          call_case(clauses[self._name], *@_values)
        elsif clauses.key?(:other)
          call_case(clauses[:other])
        else
          raise TypeError.new("no case for #{self._name}")
        end
      end

      def self.from_sexpr(sexpr)
        if sexpr.is_a?(Array) && sexpr.size > 0 && sexpr[0].is_a?(Symbol)
          name, *args = sexpr
          send(name, *args.map(&method(:from_sexpr)))
        else
          sexpr
        end
      end

      def inspect
        "<#{_variant}.#{_name}(#{@_values.map(&:inspect).join(', ')})>"
      end

      private

      def call_case(case_val, *args)
        if case_val.is_a? Proc
          case_val.call(*args)
        else
          case_val
        end
      end
    end
  end
end
