require 'spec_helper'
require 'dentaku/calculator'

describe Dentaku::Calculator do
  describe 'functions' do
    describe 'external functions' do

      let(:with_external_funcs) do
        c = described_class.new

        c.add_function("now() = :string", -> { Time.now.to_s })

        fns = [
          ["pow(:numeric, :numeric) = :numeric", ->(mantissa, exponent) { mantissa ** exponent }],
          ["biggest([:numeric], :string) = :numeric", ->(args, str) { args.max }],
          ["smallest([:numeric]) = :numeric", ->(args) { args.min }],
          ["match(:string, :string) = :boolean", ->(a, b) { a == b }],
          ['key_count({ foo: :numeric, bar: :numeric, baz: :numeric }, [%a], :string, :string) = :numeric', ->(fee_by_type, values, type_key, quantity_key) {
            return fee_by_type.keys.length
          }],
        ]

        c.add_functions(fns)
      end

      it 'includes NOW' do
        now = with_external_funcs.evaluate('NOW()')
        expect(now).not_to be_nil
        expect(now).not_to be_empty
      end

      it 'includes POW' do
        expect(with_external_funcs.evaluate('POW(2,3)')).to eq(8)
        expect(with_external_funcs.evaluate('POW(3,2)')).to eq(9)
        expect(with_external_funcs.evaluate('POW(mantissa,exponent)', input(mantissa: 2, exponent: 4))).to eq(16)
      end

      it 'includes BIGGEST' do
        expect(with_external_funcs.evaluate('BIGGEST(list, "foo")', input(list: [8,6,7,5,3,0,9]))).to eq(9)
      end

      it 'includes MIN and MAX' do
        expect(with_external_funcs.evaluate('MIN([field,2])', input(field: 100))).to eq(2)
        expect(with_external_funcs.evaluate('MAX([field,2])', input(field: 1))).to eq(2)
      end

      it 'includes SMALLEST' do
        expect(with_external_funcs.evaluate('SMALLEST(list)', input(list: [8,6,7,5,3,0,9]))).to eq(0)
      end

      it 'supports array parameters' do
        calculator = described_class.new
        calculator.add_function(
          "includes([%a], %a) = :bool",
          ->(haystack, needle) {
            haystack.include?(needle)
          }
        )

        expect(calculator.evaluate("INCLUDES(list, 2)", input(list: [1,2,3]))).to eq(true)
      end

      it 'supports normal parameters' do
        result = with_external_funcs.evaluate("match('abc-def-ghi', '^[a-z]{3}-[a-z]{3}-[a-z]{3}$')")
        expect(result).to eq(false)
      end

      it 'supports dictionary parameters' do
        result = with_external_funcs.evaluate("key_count({ foo: 1.1, bar: 2.2, baz: 3 }, [], 'plumbing_fixture_type', 'plumbing_fixture_quantity')")
        expect(result).to eq(3)
      end
    end
  end
end
