# -----------------------------------------------------------------------------
#
# Axis object tests
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

    class TestAxes < ::MiniTest::Unit::TestCase  # :nodoc:


      def test_labeled_axis_size
        axis_ = LabeledAxis.new([:one, :two])
        assert_equal(2, axis_.size)
      end


      def test_labeled_axis_label_to_index
        axis_ = LabeledAxis.new([:one, :two])
        assert_equal(0, axis_.label_to_index(:one))
        assert_equal(1, axis_.label_to_index(:two))
        assert_equal(0, axis_.label_to_index('one'))
        assert_nil(axis_.label_to_index(:three))
      end


      def test_labeled_axis_index_to_label
        axis_ = LabeledAxis.new([:one, :two])
        assert_equal('one', axis_.index_to_label(0))
        assert_equal('two', axis_.index_to_label(1))
        assert_nil(axis_.index_to_label(2))
      end


      def test_labeled_axis_equality
        axis1_ = LabeledAxis.new([:one, :two])
        axis2_ = LabeledAxis.new([:one, 'two'])
        axis3_ = LabeledAxis.new([:one, :three])
        assert_equal(axis1_, axis2_)
        refute_equal(axis1_, axis3_)
      end


      def test_labeled_axis_empty
        axis_ = LabeledAxis.new([])
        assert_equal(0, axis_.size)
      end


      def test_object_axis_size
        axis_ = ObjectAxis.new([:one, :two])
        assert_equal(2, axis_.size)
      end


      def test_object_axis_label_to_index
        axis_ = ObjectAxis.new([:one, :two])
        assert_equal(0, axis_.label_to_index(:one))
        assert_equal(1, axis_.label_to_index(:two))
        assert_nil(axis_.label_to_index('one'))
        assert_nil(axis_.label_to_index(:three))
      end


      def test_object_axis_index_to_label
        axis_ = ObjectAxis.new([:one, :two])
        assert_equal(:one, axis_.index_to_label(0))
        assert_equal(:two, axis_.index_to_label(1))
        assert_nil(axis_.index_to_label(2))
      end


      def test_object_axis_equality
        axis1_ = ObjectAxis.new([:one, :two])
        axis2_ = ObjectAxis.new([:one, :two])
        axis3_ = ObjectAxis.new([:one, 'two'])
        assert_equal(axis1_, axis2_)
        refute_equal(axis1_, axis3_)
      end


      def test_object_axis_empty
        axis_ = ObjectAxis.new([])
        assert_equal(0, axis_.size)
      end


      def test_indexed_axis_size
        axis_ = IndexedAxis.new(2)
        assert_equal(2, axis_.size)
      end


      def test_indexed_axis_label_to_index
        axis_ = IndexedAxis.new(2, 4)
        assert_equal(0, axis_.label_to_index(4))
        assert_equal(1, axis_.label_to_index(5))
        assert_nil(axis_.label_to_index(3))
      end


      def test_indexed_axis_index_to_label
        axis_ = IndexedAxis.new(2, 4)
        assert_equal(4, axis_.index_to_label(0))
        assert_equal(5, axis_.index_to_label(1))
        assert_nil(axis_.index_to_label(2))
      end


      def test_indexed_axis_equality
        axis1_ = IndexedAxis.new(2, 4)
        axis2_ = IndexedAxis.new(2, 4)
        axis3_ = IndexedAxis.new(2, 3)
        assert_equal(axis1_, axis2_)
        refute_equal(axis1_, axis3_)
      end


      def test_indexed_axis_empty
        axis_ = IndexedAxis.new(0)
        assert_equal(0, axis_.size)
      end


    end

  end
end
