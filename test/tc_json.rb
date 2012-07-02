# -----------------------------------------------------------------------------
#
# Basic table values tests
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


require 'test/unit'
require 'ntable'


module NTable
  module Tests  # :nodoc:

    class TestJSON < ::Test::Unit::TestCase  # :nodoc:


      def setup
        @labeled_axis_2 = LabeledAxis.new([:one, :two])
        @labeled_axis_3 = LabeledAxis.new([:red, :white, :blue])
        @indexed_axis_2 = IndexedAxis.new(2)
        @indexed_axis_10 = IndexedAxis.new(10, 1)
      end


      def test_labeled_axis_2
        json_ = {}
        @labeled_axis_2.to_json_object(json_)
        assert_equal({'labels' => ['one', 'two']}, json_)
        naxis_ = LabeledAxis.allocate
        naxis_.from_json_object(json_)
        assert_equal(@labeled_axis_2, naxis_)
      end


      def test_labeled_axis_3
        json_ = {}
        @labeled_axis_3.to_json_object(json_)
        assert_equal({'labels' => ['red', 'white', 'blue']}, json_)
        naxis_ = LabeledAxis.allocate
        naxis_.from_json_object(json_)
        assert_equal(@labeled_axis_3, naxis_)
      end


      def test_indexed_axis_2
        json_ = {}
        @indexed_axis_2.to_json_object(json_)
        assert_equal({'size' => 2}, json_)
        naxis_ = IndexedAxis.allocate
        naxis_.from_json_object(json_)
        assert_equal(@indexed_axis_2, naxis_)
      end


      def test_indexed_axis_10
        json_ = {}
        @indexed_axis_10.to_json_object(json_)
        assert_equal({'size' => 10, 'start' => 1}, json_)
        naxis_ = IndexedAxis.allocate
        naxis_.from_json_object(json_)
        assert_equal(@indexed_axis_10, naxis_)
      end


      def test_structure
        structure_ = Structure.add(@indexed_axis_10, 'row').add(@indexed_axis_2).add(@labeled_axis_3, 'col')
        json_ = structure_.to_json_array
        expected_json_ = [
          {'type' => 'indexed', 'name' => 'row', 'size' => 10, 'start' => 1},
          {'type' => 'indexed', 'size' => 2},
          {'type' => 'labeled', 'name' => 'col', 'labels' => ['red', 'white', 'blue']}
        ]
        assert_equal(expected_json_, json_)
        nstructure_ = Structure.from_json_array(json_)
        assert_equal(structure_, nstructure_)
      end


      def test_empty_structure
        structure_ = Structure.new
        json_ = structure_.to_json_array
        assert_equal([], json_)
        nstructure_ = Structure.from_json_array(json_)
        assert_equal(structure_, nstructure_)
      end


      def test_table_2d_json_object
        table_ = Table.new(Structure.add(@indexed_axis_10, 'row').add(@labeled_axis_3, 'col'),
          :load => (0..29).to_a)
        json_ = table_.to_json_object
        expected_json_ = {
          'axes' => [{'type' => 'indexed', 'name' => 'row', 'size' => 10, 'start' => 1},
            {'type' => 'labeled', 'name' => 'col', 'labels' => ['red', 'white', 'blue']}],
          'values' => (0..29).to_a
        }
        assert_equal(expected_json_, json_)
        ntable_ = Table.from_json_object(json_)
        assert_equal(table_, ntable_)
      end


    end

  end
end
