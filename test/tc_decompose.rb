# -----------------------------------------------------------------------------
#
# Table decomposition tests
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

    class TestDecompose < ::MiniTest::Unit::TestCase  # :nodoc:


      def setup
        @labeled_axis_2 = LabeledAxis.new([:one, :two])
        @indexed_axis_10 = IndexedAxis.new(10,1)
        @indexed_axis_0 = IndexedAxis.new(0)
        @scalar_structure = Structure.new
        @structure_row = Structure.add(@labeled_axis_2)
        @structure_1d = Structure.add(@indexed_axis_10)
        @structure_2d = Structure.add(@indexed_axis_10).add(@labeled_axis_2)
        @empty_structure = Structure.add(@indexed_axis_0)
      end


      def test_scalar_decompose
        t1_ = Table.new(@scalar_structure, :load => [:foo])
        t2_ = t1_.decompose([])
        assert_equal(0, t2_.dim)
        assert_equal(1, t2_.size)
        assert_equal(t1_, t2_.get)
      end


      def test_1d_decompose_inner
        t1_ = Table.new(@structure_1d, :load => (2..11).to_a)
        t2_ = t1_.decompose([0])
        assert_equal(0, t2_.dim)
        assert_equal(1, t2_.size)
        assert_equal(t1_, t2_.get)
      end


      def test_1d_decompose_outer
        t1_ = Table.new(@structure_1d, :load => (2..11).to_a)
        t2_ = t1_.decompose([])
        assert_equal(Table.new(@scalar_structure, :load => [2]), t2_.get(1))
        assert_equal(Table.new(@scalar_structure, :load => [3]), t2_.get(2))
      end


      def test_2d_decompose
        t1_ = Table.new(@structure_2d, :load => (2..21).to_a)
        t2_ = t1_.decompose([1])
        assert_equal(Table.new(@structure_row, :load => [2, 3]), t2_.get(1))
        assert_equal(Table.new(@structure_row, :load => [4, 5]), t2_.get(2))
      end


      def test_2d_decompose_reduce
        t1_ = Table.new(@structure_2d, :load => (2..21).to_a)
        t2_ = t1_.decompose_reduce([1], :*)
        assert_equal(6, t2_.get(1))
        assert_equal(20, t2_.get(2))
      end


    end

  end
end
