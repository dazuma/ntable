# -----------------------------------------------------------------------------
#
# Test serialization as nested objects
#
# -----------------------------------------------------------------------------
# Copyright 2012 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------
;


require 'minitest/autorun'
require 'ntable'


module NTable
  module Tests  # :nodoc:

    class TestNestedObject < ::MiniTest::Unit::TestCase  # :nodoc:


      def setup
        @labeled_axis_2 = LabeledAxis.new([:one, :two])
        @object_axis_2 = ObjectAxis.new([:one, :two])
        @object_axis_3 = ObjectAxis.new([:one, :two, :three])
        @labeled_axis_3 = LabeledAxis.new([:blue, :red, :white])
        @indexed_axis_2 = IndexedAxis.new(2)
        @indexed_axis_10 = IndexedAxis.new(10, 1)
        @labeled_axis_0 = LabeledAxis.new([])
        @indexed_axis_0 = IndexedAxis.new(0)
      end


      def test_from_empty_labeled
        t1_ = Table.from_nested_object({})
        assert_equal(Table.new(Structure.add(@labeled_axis_0)), t1_)
      end


      def test_to_empty_labeled
        t1_ = Table.new(Structure.add(@labeled_axis_0))
        assert_equal({}, t1_.to_nested_object)
      end


      def test_from_level_1_labeled
        obj_ = {:one => 1, :two => 2}
        t1_ = Table.from_nested_object(obj_, [{:sort => true}])
        assert_equal(Table.new(Structure.add(@labeled_axis_2), :load => [1,2]), t1_)
      end


      def test_to_level_1_labeled
        t1_ = Table.new(Structure.add(@labeled_axis_2), :load => [1,2])
        assert_equal({'one' => 1, 'two' => 2}, t1_.to_nested_object)
      end


      def test_from_level_2_labeled
        obj_ = {:one => {:red => 1, :white => 2}, :two => {:white => 3, :blue => 4}}
        t1_ = Table.from_nested_object(obj_, [{:sort => true}, {:sort => true}])
        assert_equal(Table.new(Structure.add(@labeled_axis_2).add(@labeled_axis_3),
          :load => [nil, 1, 2, 4, nil, 3]), t1_)
        t2_ = Table.from_nested_object(obj_, [{:sort => true}, {:sort => true}], :fill => :foo)
        assert_equal(Table.new(Structure.add(@labeled_axis_2).add(@labeled_axis_3),
          :load => [:foo, 1, 2, 4, :foo, 3]), t2_)
      end


      def test_to_level_2_labeled
        t1_ = Table.new(Structure.add(@labeled_axis_2).add(@labeled_axis_3),
          :load => [nil, 1, 2, 4, nil, 3])
        assert_equal({'one' => {'red' => 1, 'white' => 2}, 'two' => {'white' => 3, 'blue' => 4}},
          t1_.to_nested_object(:exclude_value => nil))
        assert_equal({'one' => {'red' => 1, 'white' => 2, 'blue' => nil}, 'two' => {'red' => nil, 'white' => 3, 'blue' => 4}},
          t1_.to_nested_object)
      end


      def test_from_empty_indexed
        t1_ = Table.from_nested_object([])
        assert_equal(Table.new(Structure.add(@indexed_axis_0)), t1_)
      end


      def test_to_empty_indexed
        t1_ = Table.new(Structure.add(@indexed_axis_0))
        assert_equal([], t1_.to_nested_object)
      end


      def test_from_level_1_start_0_indexed
        obj_ = [2, 3]
        t1_ = Table.from_nested_object(obj_)
        assert_equal(Table.new(Structure.add(@indexed_axis_2), :load => [2,3]), t1_)
      end


      def test_to_level_1_start_0_indexed
        t1_ = Table.new(Structure.add(@indexed_axis_2), :load => [2, 3])
        assert_equal([2, 3], t1_.to_nested_object)
      end


      def test_from_level_1_start_1_indexed
        obj_ = [nil] + (2..11).to_a
        t1_ = Table.from_nested_object(obj_)
        assert_equal(Table.new(Structure.add(@indexed_axis_10), :load => (2..11).to_a), t1_)
      end


      def test_to_level_1_start_1_indexed
        t1_ = Table.new(Structure.add(@indexed_axis_10), :load => (2..11).to_a)
        assert_equal([nil] + (2..11).to_a, t1_.to_nested_object)
      end


      def test_from_level_1_start_1_indexed_with_postprocess
        obj_ = (1..12).to_a
        t1_ = Table.from_nested_object(obj_,
          [{:postprocess_range => ->(r_){ (1..10) }}])
        assert_equal(Table.new(Structure.add(@indexed_axis_10), :load => (2..11).to_a), t1_)
      end


      def test_from_level_2_indexed
        obj_ = [[nil, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], []]
        t1_ = Table.from_nested_object(obj_)
        assert_equal(Table.new(Structure.add(@indexed_axis_2).add(@indexed_axis_10),
          :load => (2..11).to_a + ::Array.new(10)), t1_)
      end


      def test_to_level_2_indexed
        t1_ = Table.new(Structure.add(@indexed_axis_2).add(@indexed_axis_10),
          :load => (2..21).to_a)
        assert_equal([[nil] + (2..11).to_a, [nil] + (12..21).to_a], t1_.to_nested_object)
      end


      def test_from_labeled_within_indexed
        obj_ = [{:red => 1, :white => 2, :blue => 3}, {:red => 4, :white => 5}]
        t1_ = Table.from_nested_object(obj_, [{:name => 'row'}, {:name => 'col', :sort => true}])
        assert_equal(Table.new(Structure.add(@indexed_axis_2, 'row').add(@labeled_axis_3, 'col'),
          :load => [3, 1, 2, nil, 4, 5]), t1_)
      end


      def test_to_labeled_within_indexed
        t1_ = Table.new(Structure.add(@indexed_axis_2, 'row').add(@labeled_axis_3, 'col'),
          :load => [3, 1, 2, 6, 4, 5])
        assert_equal([{'red' => 1, 'white' => 2, 'blue' => 3}, {'red' => 4, 'white' => 5, 'blue' => 6}],
          t1_.to_nested_object)
      end


      def test_from_indexed_within_labeled
        obj_ = {:red => [1,2], :white => [3], :blue => [4,5]}
        t1_ = Table.from_nested_object(obj_, [{:name => 'row', :sort => true}, {:name => 'col'}])
        assert_equal(Table.new(Structure.add(@labeled_axis_3, 'row').add(@indexed_axis_2, 'col'),
          :load => [4, 5, 1, 2, 3]), t1_)
      end


      def test_to_indexed_within_labeled
        t1_ = Table.new(Structure.add(@labeled_axis_3, 'row').add(@indexed_axis_2, 'col'),
          :load => [4, 5, 1, 2, 3, 6])
        assert_equal({'red' => [1,2], 'white' => [3, 6], 'blue' => [4,5]},
          t1_.to_nested_object)
      end


      def test_from_level_1_labeled_with_objectify
        obj_ = {:one => 1, :two => 2}
        t1_ = Table.from_nested_object(obj_, [{:sort => true, :objectify => true}])
        assert_equal(Table.new(Structure.add(@object_axis_2), :load => [1,2]), t1_)
      end


      def test_to_level_1_labeled_with_objectify
        t1_ = Table.new(Structure.add(@object_axis_2), :load => [1,2])
        assert_equal({:one => 1, :two => 2}, t1_.to_nested_object)
      end


      def test_from_level_1_labeled_with_objectify_conversion
        obj_ = {'one' => 1, 'two' => 2}
        t1_ = Table.from_nested_object(obj_,
          [{:sort => true, :objectify => ->(a_){ a_.to_sym }}])
        assert_equal(Table.new(Structure.add(@object_axis_2), :load => [1,2]), t1_)
      end


      def test_from_level_1_labeled_with_stringify_conversion
        obj_ = {:one1 => 1, :two22 => 2}
        t1_ = Table.from_nested_object(obj_,
          [{:sort => true, :stringify => ->(a_){ a_.to_s.gsub(/\d/, '') }}])
        assert_equal(Table.new(Structure.add(@labeled_axis_2), :load => [1,2]), t1_)
      end


      def test_from_level_1_labeled_with_objectify_and_postprocess
        obj_ = {:one => 1, :two => 2}
        t1_ = Table.from_nested_object(obj_,
          [{:sort => true, :objectify => true, :postprocess_labels => ->(labels_){ labels_ << :three }}],
          :fill => 0)
        assert_equal(Table.new(Structure.add(@object_axis_3), :load => [1,2,0]), t1_)
      end


    end

  end
end
