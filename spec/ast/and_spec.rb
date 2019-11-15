require 'spec_helper'
require 'dentaku/ast/combinators'

require 'dentaku/token'

describe Dentaku::AST::And do
  let(:t) { Dentaku::AST::Logical.new Dentaku::Token.new(:logical, true)  }
  let(:f) { Dentaku::AST::Logical.new Dentaku::Token.new(:logical, false) }

  let(:five) { Dentaku::AST::Numeric.new Dentaku::Token.new(:numeric, 5) }

  let(:calculator) { Dentaku::Calculator.new }

  it 'performs logical AND' do
    node = described_class.new(t, f)
    expect(calculator.evaluate!(node)).to eq false
  end

  describe 'branch favoring' do
    let(:calculator) { Dentaku::Calculator.new.tap { |c| c.cache = {} } }
    let(:expression) do
      'a AND b AND c AND D'
    end

    let(:data) { {} }

    let(:evaluation) { calculator.evaluate!(expression, data) }

    context 'with no dependents' do
      it 'should evaluate in order' do
        expect { evaluation }.to raise_error(Dentaku::UnboundVariableError)
        expect(calculator.cache.unsatisfied_identifiers).to include("a")
        expect(calculator.cache.unsatisfied_identifiers).not_to include("b")
      end
    end

    %w[a b c d].each_with_index do |key, i|
      context "with dependent #{i}/4" do
        let(:data) { { key => false } }

        it 'should evaluate existing branches first' do
          expect(evaluation).to be false
          expect(calculator.cache.unsatisfied_identifiers).to be_empty
          expect(calculator.cache.satisfied_identifiers).to include(key)
        end
      end
    end
  end
end
