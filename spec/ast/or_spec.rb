require 'spec_helper'
require 'dentaku/ast/combinators'

require 'dentaku/token'

describe Dentaku::AST::Or do
  let(:calculator) { Dentaku::Calculator.new.tap { |c| c.cache = {} } }

  describe 'branch favoring' do
    let(:expression) do
      'a OR b OR c or D'
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
        let(:data) { { key => true } }

        it 'should evaluate existing branches first' do
          expect(evaluation).to be true
          expect(calculator.cache.unsatisfied_identifiers).to be_empty
          expect(calculator.cache.satisfied_identifiers).to include(key)
        end
      end
    end
  end
end
