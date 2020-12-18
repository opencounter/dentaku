module Dentaku
  module Type
    class Expression < Variant
      variants(
        syntax: [:ast],
        param: [:name, :arguments],
        dictionary: [:keys, :types],
        variable: [:name, :uniq],
        var: [:name],
      )

      def self.concrete(name)
        param(name, [])
      end

      def self.uniq
        Thread.current[:dentaku_type_uniq_counter] ||= 0
        Thread.current[:dentaku_type_uniq_counter] += 1
      end

      def self.make_variable(name)
        variable(name, uniq)
      end

      def self.from_sexpr(sexpr)
        if sexpr.is_a?(String)
          Syntax.parse_type(sexpr)
        else
          super
        end
      end

      def map(&blk)
        cases(
          param: ->(name, arguments) {
            Expression.param(name, arguments.map(&blk))
          },
          dictionary: ->(keys, types) {
            Expression.dictionary(keys, types.map(&blk))
          },
          other: self
        )
      end

      def resolve(reverse_scope={})
        cases(
          param: ->(name, arguments) {
            if name == :bool && arguments.empty?
              Type.bool
            elsif name == :numeric && arguments.empty?
              Type.numeric
            elsif name == :string && arguments.empty?
              Type.string
            elsif name == :range && arguments.empty?
              Type.range
            elsif name == :date && arguments.empty?
              Type.date
            elsif name == :list && arguments.size == 1
              Type.list(arguments[0].resolve(reverse_scope))
            elsif name == :pair && arguments.size == 2
              Type.pair(*arguments.map { |a| a.resolve(reverse_scope) })
            else
              raise RuntimeError, "Unresolvable type expression #{self.repr}"
            end
          },
          variable: -> (name, uniq) {
            var_name = reverse_scope[[name, uniq]]
            next Type.abstract unless var_name
            Type.bound(var_name)
          },
          dictionary: -> (keys, types) {
            Type.dictionary(keys, types.map { |t| t.resolve(reverse_scope) })
          },
          other: ->() {
            Type.abstract
          }
        )
      end

      def resolve_vars(scope={})
        cases(
          var: ->(name) {
            scope[name] ||= Expression.variable(name, self.class.uniq)
          },
          other: -> { map { |x| x.resolve_vars(scope) } },
        )
      end

      def expression_hash
        cases(
          syntax: ->(ast) {
            ast.loc_range.inspect + ast.repr
          },
          other: ->(*) { repr }
        )
      end

      def ==(other)
        self.expression_hash == other.expression_hash
      end

      def inspect
        "<Type::Expression #{repr}>"
      end

      def repr
        cases(
          syntax: ->(ast) { "(#{ast.repr})" },
          param: ->(name, arguments) {
            if arguments.empty?
              ":#{name}"
            else
              ":#{name}(#{arguments.map(&:repr).join(' ')})"
            end
          },
          variable: ->(name, uniq) { "%#{name}#{uniq}" },
          var: -> (name) { "%%#{name}" },
          dictionary: -> (keys, values) {
            "{#{keys.zip(values).map { |(k, v)| "#{k}: #{v.repr}" }.join(', ')}}"
          },
        )
      end

    end
  end
end
