module Dentaku
  module Syntax
    module Parser
      extend self

      def parse(skel)
        if skel.root?
          parse_elems_of(skel)
        else
          parse_expr([skel])
        end
      end

    protected

      def parse_elems_of(node)
        return invalid node, "empty expression" if node.elems.empty?

        parse_expr(node.elems)
      end

      def parse_expr(elems)
        if elems.empty?
          # [jneen] while the caller can provide a proper location pointer for
          # an empty expression, it's impossible once we get to here and only have
          # an empty list. this is why it's the caller's responsibility to make
          # sure the argument to parse_expr is nonempty.
          raise "DENTAKU BUG: check for empty expressions before calling parse_expr"
        end

        return parse_combinator(elems)
      end

      def parse_combinator(elems)
        before, op, after = rpart(elems) { |e| e.token?(:combinator) }
        return parse_comparator(elems) if op.nil?


        lhs = nonempty!(op, before) { parse_combinator(before) }
        rhs = nonempty!(op, after) { parse_comparator(after) }

        (op.value == :and ? AST::And : AST::Or).make(elems, lhs, rhs)
      end

      # next precedence: comparator ops: < > = != etc
      def parse_comparator(elems)
        before, op, after = rpart(elems) { |e| e.token?(:comparator) }
        return parse_range(elems) if op.nil?

        lhs = nonempty!(op, before) { parse_comparator(before) }
        rhs = nonempty!(op, after) { parse_range(after) }

        op_class = case op.value
        when :<= then AST::LessThanOrEqual
        when :>= then AST::GreaterThanOrEqual
        when :< then AST::LessThan
        when :> then AST::GreaterThan
        when :!=, :'<>' then AST::NotEqual
        when :==, :'=' then AST::Equal
        else return invalid op, 'unknown comparison operator', lhs, rhs
        end

        op_class.make(elems, lhs, rhs)
      end

      # next precedence: range expressions A..B
      def parse_range(elems)
        before, op, after = rpart(elems) { |e| e.token?(:range) }
        return parse_additive(elems) if op.nil?

        lhs = nonempty!(op, before) { parse_additive(before) }
        rhs = nonempty!(op, after) { parse_range(after) }

        AST::Range.make(elems, lhs, rhs)
      end

      def parse_additive(elems)
        before, op, after = rpart(elems) { |e| e.token?(:additive) }
        return parse_multiplicative(elems) if op.nil?

        lhs = nonempty!(op, before) { parse_additive(before) }
        rhs = nonempty!(op, after) { parse_multiplicative(after) }

        return case op.value
        when '-' then AST::Subtraction.make(elems, lhs, rhs)
        when '+' then AST::Addition.make(elems, lhs, rhs)
        else invalid op, 'unknown additive operation', lhs, rhs
        end

        return parse_multiplicative(elems)
      end

      def parse_multiplicative(elems)
        before, op, after = rpart(elems) { |e| e.token?(:multiplicative) }
        return parse_exponential(elems) if op.nil?

        lhs = nonempty!(op, before) { parse_multiplicative(before) }
        rhs = nonempty!(op, after) { parse_exponential(after) }

        case op.value
        when '*' then AST::Multiplication.make(elems, lhs, rhs)
        when '/' then AST::Division.make(elems, lhs, rhs)
        when '%' then AST::Modulo.make(elems, lhs, rhs)
        else invalid op, 'unknown multiplicative operation', lhs, rhs
        end
      end

      def parse_exponential(elems)
        before, op, after = rpart(elems) { |x| x.token?(:exponential) }
        return parse_minus(elems) if op.nil?

        lhs = nonempty!(op, before) { parse_exponential(before) }
        rhs = nonempty!(op, after) { parse_minus(after) }

        AST::Exponentiation.make(elems, lhs, rhs)
      end

      def parse_minus(elems)
        return parse_funcall(elems) unless elems.first.token?(:minus)
        first, *rest = elems
        return nonempty!(first, rest) { AST::Negation.make(elems, parse_minus(rest)) }
      end

      def parse_funcall(elems)
        return parse_check_error(elems) unless elems.size == 2
        func, args = elems
        return parse_check_error(elems) unless func.token?(:identifier)
        return parse_check_error(elems) unless args.nested?(:lparen)

        fn = AST::Function.get(func.value, func)
        fn.make(elems, *parse_comma_sep(args.elems))
      end

      def parse_check_error(elems)
        before, err, after = lpart(elems, &:error?)

        return invalid(err, err.message) if err

        before, comma, after = lpart(elems) { |e| e.token?(:comma) }

        if comma
          before_exp = before.any? ? parse_singleton(before) : nil
          after_exp = after.any? ? parse_check_error(after) : nil
          return invalid(comma, "stray comma", before_exp, after_exp) if comma
        end

        parse_singleton(elems)
      end

      # the end of the precedence chain. here we expect to have handled all
      # infix operators or expressions that could span more than one skeleton
      # node.
      def parse_singleton(elems)
        if elems.empty?
          # [jneen] same as the check in parse_expr, but for all the parse_*
          # methods above that *could* have drilled down to empty. it's important
          # that they handle the empty case above where there is error reporting
          # information available before stranding us here with an empty list.
          raise "DENTAKU BUG: check for empty expressions before calling parse_expr"
        end

        if elems.size > 1
          individual = elems.map { |e| parse_singleton([e]) }
          return invalid elems, 'too many expressions: missing a comma or operator?', *individual
        end

        node = elems.first

        return AST::Identifier.make(node, node.value) if node.token?(:identifier)
        return AST::String.make(node, node.value) if node.token?(:string)
        return AST::Numeric.make(node, node.value) if node.token?(:numeric)
        return AST::Logical.make(node, node.value) if node.token?(:logical)

        return parse_case(node) if node.nested?(:case)
        return AST::List.make(node, *parse_comma_sep(node.elems)) if node.nested?(:lbrack)
        return parse_struct(node) if node.nested?(:lbrace)
        return parse_elems_of(node) if node.nested?(:lparen)

        return invalid node, node.message if node.error?
        return invalid single, "unrecognized syntax"
      end

      def parse_struct(struct)
        pairs = parse_comma_sep(struct.elems) do |segment|
          next ['_', invalid(struct, 'empty struct segment')] if segment.empty?
          key = segment.shift
          next [key.repr, invalid(key, 'invalid key')] unless key.token?(:key)
          next [key.value, invalid(key, 'empty expression')] if segment.empty?

          [key.value, parse_expr(segment)]
        end

        AST::Struct.make(struct, *pairs)
      end

      # parse a comma separated list
      def parse_comma_sep(args, &b)
        return [] if args.empty?

        b ||= method(:parse_expr)

        out = []

        loop do
          before, comma, after = lpart(args) { |a| a.token?(:comma) }
          break if comma.nil?
          out << nonempty!(comma, before) { b.call(before) }
          args = after
        end

        # if there is anymore, parse it out and add it on. otherwise,
        # it's a trailing comma, so we ignore it.
        out << b.call(args) if args.any?

        out
      end

      # there's a lot in this method but it's all fairly fundamental features
      # of CASE. we're receiving one skeleton node that neatly wraps up the
      # CASE...END grouping, but has everything else pretty much in a grab bag
      # inside. so we have to find the WHEN/THEN/ELSE tokens and group them
      # here
      def parse_case(case_node)
        # separate into arrays of clauses, such that the WHEN/THEN/ELSE token
        # is at the front of the array.
        # e.g. [[ {token :when} {token :logical("true")} ],
        #       [ {token :then} ... ],
        #       [ {token :else} ... ]]
        #
        # See Syntax::Token#clause, which returns true if the token is
        # one of when, then, else.
        #
        # Note this puts anything before the first clause in the first element -
        # this is conveniently the "head" or the inspected value
        clauses = [[]]
        case_node.elems.each do |elem|
          if elem.clause?
            clauses << [elem]
          else
            clauses.last << elem
          end
        end

        # head is possibly empty, for CASE WHEN ... THEN ... END
        # all other clauses guaranteed nonempty
        head = clauses.shift
        head = head.empty? ? nil : parse_expr(head)
        clauses.map! do |head, *rest|
          exp = if rest.empty?
            invalid head, "empty #{head.tok.desc.upcase} clause"
          else
            parse_expr(rest)
          end

          [head, exp]
        end

        # once head is popped, there should be an even number of clauses, except
        # possibly for the singular ELSE clause at the end
        last = (clauses.pop if clauses.size.odd?)

        # i don't think there's a use case for CASE ELSE ... END but hey it'd
        # technically work. disallowing it here tho
        if clauses.empty?
          return invalid case_node, 'a CASE statement must have at least one clause'if clauses.empty?
        end

        # `clauses` is even-sized now, so let's group them in pairs that *should*
        # be when/then
        pairs = make_pairs(clauses)

        # make sure each pair is *actuall* when followed by then, and only
        # grab the resulting AST
        pairs.map! do |(w, t)|
          when_tok, when_exp = w
          unless when_tok.token?(:when)
            when_exp = invalid(when_tok, 'expected a WHEN clause', when_exp)
          end

          then_tok, then_exp = t
          unless then_tok.token?(:then)
            then_exp = invalid(then_tok, 'expected a THEN clause', then_exp)
          end

          [when_exp, then_exp]
        end

        # if there was an odd clause at the end, make sure it's an ELSE
        else_exp = nil
        if last
          else_tok, else_exp = last
          unless else_tok.token?(:else)
            else_exp = invalid else_tok, "hanging #{else_tok.tok.category.to_s.upcase} clause", else_exp
          end
        end

        AST::Case.make(case_node, head, pairs, else_exp)
      end

      # in_groups_of(2), but without rails
      # [a, b, c, d, e, f] => [[a, b], [c, d], [e, f]]
      # arr guaranteed to be even size before calling.
      def make_pairs(arr)
        # pre-allocate the entire array since we know its size
        out = Array.new(arr.size/2) { [nil, nil] }
        arr.each_with_index do |e, i|
          j, k = i.divmod(2)
          out[j][k] = e
        end

        out
      end

      # rpart and lpart attempt to split a list on an element that passes
      # a predicate. they can be *very* fast using Array#index and Array#rindex.
      def rpart(list, &pred)
        index = list.rindex(&pred) or return nil

        [list.take(index), list[index], list.drop(index+1)]
      end

      def lpart(list, &pred)
        index = list.index(&pred) or return nil

        [list.take(index), list[index], list.drop(index+1)]
      end

      # helper to make sure a segment is nonempty before proceeding. returns
      # an invalid node with the given reference elems if the expression is
      # empty.
      def nonempty!(ref_elems, elems)
        return invalid ref_elems, "empty expression" if elems.empty?
        yield
      end

      def invalid(node, message, *children)
        AST::Invalid.make(node, message, *children)
      end
    end
  end
end
