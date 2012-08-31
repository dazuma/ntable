# -----------------------------------------------------------------------------
#
# Table slicing tests
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

    class TestSlice < ::MiniTest::Unit::TestCase  # :nodoc:


      def setup
        @labeled_axis_2 = LabeledAxis.new([:one, :two])
        @labeled_axis_3 = LabeledAxis.new([:red, :white, :blue])
        @indexed_axis_2 = IndexedAxis.new(2)
        @indexed_axis_10 = IndexedAxis.new(10,1)
        @indexed_axis_0 = IndexedAxis.new(0)
      end


      def test_slice_of_no_axes
        t1_ = Table.new(Structure.new)
        t2_ = t1_.slice({})
        assert_equal(t1_, t2_)
      end


      def test_nop_slice_1
        t1_ = Table.new(Structure.new.add(@labeled_axis_2), :fill => 1)
        t1s_ = t1_.slice({})
        assert_equal(t1_, t1s_)
      end


      def test_nop_slice_2
        t1_ = Table.new(Structure.new.add(@indexed_axis_10, :row).add(@labeled_axis_3, :column), :fill => 1)
        t1s_ = t1_.slice({})
        assert_equal(t1_, t1s_)
      end


      def test_slice_1_to_0_indexed
        t1_ = Table.new(Structure.new.add(@indexed_axis_10, :row), :load => (2..11).to_a)
        t1s_ = t1_.slice(:row => 3)
        assert_equal(4, t1s_.get)
      end


      def test_slice_1_to_0_labeled
        t1_ = Table.new(Structure.new.add(@labeled_axis_3, :col), :load => [2,3,4])
        t1s_ = t1_.slice(:col => :white)
        assert_equal(3, t1s_.get)
      end


      def test_slice_2_to_0
        s1_ = Structure.new.add(@indexed_axis_10, :row).add(@labeled_axis_3, :col)
        t1_ = Table.new(s1_, :load => (2..31).to_a)
        t1s_ = t1_.slice(:row => 2, :col => :white)
        assert_equal(6, t1s_.get)
      end


      def test_slice_2_to_1_major
        s1_ = Structure.new.add(@indexed_axis_10, :row).add(@labeled_axis_3, :col)
        t1_ = Table.new(s1_, :load => (2..31).to_a)
        t1s_ = t1_.slice(:row => 2)
        t2_ = Table.new(Structure.new.add(@labeled_axis_3, :col), :load => [5,6,7])
        assert_equal(t2_, t1s_)
      end


      def test_slice_2_to_1_minor
        s1_ = Structure.new.add(@indexed_axis_10, :row).add(@labeled_axis_3, :col)
        t1_ = Table.new(s1_, :load => (2..31).to_a)
        t1s_ = t1_.slice(:col => :white)
        t2_ = Table.new(Structure.new.add(@indexed_axis_10, :row), :load => [3,6,9,12,15,18,21,24,27,30])
        assert_equal(t2_, t1s_)
      end


      def test_shared_slice_1_to_0_indexed
        t1_ = Table.new(Structure.new.add(@indexed_axis_10, :row), :load => (2..11).to_a)
        t1s_ = t1_.shared_slice(:row => 3)
        assert_equal(4, t1s_.get)
        assert_equal(Table.new(Structure.new, :load => [4]), t1s_)
        t1_.set!(3, :foo)
        assert_equal(:foo, t1s_.get)
      end


    end

  end
end
