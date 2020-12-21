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

    context "with multiple dependencies" do
      let(:data) { { "a" => false, "b" => true } }

      it "should keep a as a dependency even though it isn't touched" do
        expect(evaluation).to be true
        expect(calculator.cache.unsatisfied_identifiers).to be_empty
        expect(calculator.cache.satisfied_identifiers).to include("b")
        expect(calculator.cache.satisfied_identifiers).to include("a")
      end
    end

    context "when there is no short-circuit available" do
      let(:expression) { 'if(a, b, c) OR if(d, e, f)' }

      context "still surfaces satisfied idents" do
        let(:data) { { 'a' => true, 'b' => false, 'd' => true, 'e' => false } }
        it "records all used variables" do
          expect(evaluation).to be false
          expect(calculator.cache.unsatisfied_identifiers).to be_empty
          expect(calculator.cache.satisfied_identifiers).to eql Set[*%w[a b d e]]
        end
      end
    end

    context "it works with not(...)" do
      let(:expression) { 'not(a) or not(b) or not(c) or not(d)' }
      let(:data) { { 'c' => false } }

      it 'should still hide the unsatisfied dependencies' do
        expect(evaluation).to be true
        expect(calculator.cache.unsatisfied_identifiers).to be_empty
        expect(calculator.cache.satisfied_identifiers).to eql Set['c']
      end
    end
  end
end
