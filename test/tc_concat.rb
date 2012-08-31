# -----------------------------------------------------------------------------
#
# Table concat tests
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

    class TestConcat < ::MiniTest::Unit::TestCase  # :nodoc:


      def setup
        @labeled_axis_2 = LabeledAxis.new([:one, :two])
        @labeled_axis_3 = LabeledAxis.new([:red, :white, :blue])
        @labeled_axis_5 = LabeledAxis.new([:one, :two, :red, :white, :blue])
        @indexed_axis_2 = IndexedAxis.new(2)
        @indexed_axis_3 = IndexedAxis.new(3)
        @indexed_axis_5 = IndexedAxis.new(5)
        @indexed_axis_10 = IndexedAxis.new(10)
        @indexed_axis_12 = IndexedAxis.new(12)
        @indexed_axis_0 = IndexedAxis.new(0)
      end


      def test_concat_1d_indexed
        t1_ = Table.new(Structure.add(@indexed_axis_2), :load => [1,2])
        t2_ = Table.new(Structure.add(@indexed_axis_10), :load => (10..19).to_a)
        t3_ = Table.new(Structure.add(@indexed_axis_12), :load => (10..19).to_a + [1,2])
        assert_equal(t3_, t2_ + t1_)
        assert_equal(t3_, t2_.concat(t1_, 0))
      end


      def test_concat_1d_labeled
        t1_ = Table.new(Structure.add(@labeled_axis_2), :load => [1,2])
        t2_ = Table.new(Structure.add(@labeled_axis_3), :load => [11,12,13])
        t3_ = Table.new(Structure.add(@labeled_axis_5), :load => [1,2,11,12,13])
        assert_equal(t3_, t1_ + t2_)
        assert_equal(t3_, t1_.concat(t2_, 0))
      end


      def test_concat_2d_outer
        t1_ = Table.new(Structure.add(@indexed_axis_2, :row).add(@labeled_axis_2, :col),
          :load => [1,2,3,4])
        t2_ = Table.new(Structure.add(@indexed_axis_3, :row).add(@labeled_axis_2, :col),
          :load => [11,12,13,14,15,16])
        t3_ = Table.new(Structure.add(@indexed_axis_5, :row).add(@labeled_axis_2, :col),
          :load => [11,12,13,14,15,16,1,2,3,4])
        assert_equal(t3_, t2_ + t1_)
        assert_equal(t3_, t2_.concat(t1_, :row))
      end


      def test_concat_2d_inner
        t1_ = Table.new(Structure.add(@indexed_axis_2, :row).add(@labeled_axis_2, :col),
          :load => [1,2,3,4])
        t2_ = Table.new(Structure.add(@indexed_axis_2, :row).add(@labeled_axis_3, :col),
          :load => [11,12,13,14,15,16])
        t3_ = Table.new(Structure.add(@indexed_axis_2, :row).add(@labeled_axis_5, :col),
          :load => [1,2,11,12,13,3,4,14,15,16])
        assert_equal(t3_, t1_ + t2_)
        assert_equal(t3_, t1_.concat(t2_, :col))
      end


    end

  end
end
