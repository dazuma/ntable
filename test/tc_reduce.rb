# -----------------------------------------------------------------------------
#
# Table reduce tests
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

    class TestReduce < ::MiniTest::Unit::TestCase  # :nodoc:


      def setup
        @labeled_axis_2 = LabeledAxis.new([:one, :two])
        @indexed_axis_10 = IndexedAxis.new(10,1)
        @indexed_axis_0 = IndexedAxis.new(0)
        @scalar_structure = Structure.new
        @structure_1d = Structure.add(@indexed_axis_10)
        @structure_2d = Structure.add(@indexed_axis_10).add(@labeled_axis_2)
        @empty_structure = Structure.add(@indexed_axis_0)
      end


      def test_empty_reduce
        t1_ = Table.new(@empty_structure)
        assert_equal(nil, t1_.reduce(:+))
        assert_equal(2, t1_.reduce(2, :+))
        assert_equal(nil, t1_.reduce{ |s_, v_| flunk })
        assert_equal(2, t1_.reduce(2){ |s_, v_| flunk })
      end


      def test_empty_reduce_with_position
        t1_ = Table.new(@empty_structure)
        assert_equal(nil, t1_.reduce_with_position{ |s_, v_, p_| flunk })
        assert_equal(2, t1_.reduce_with_position(2){ |s_, v_, p_| flunk })
      end


      def test_scalar_reduce
        t1_ = Table.new(@scalar_structure, :load => [2])
        assert_equal(2, t1_.reduce(:+))
        assert_equal(5, t1_.reduce(3, :+))
        assert_equal(2, t1_.reduce{ |s_, v_| flunk })
        assert_equal(5, t1_.reduce(3){ |s_, v_| s_ + v_ })
      end


      def test_scalar_reduce_with_position
        t1_ = Table.new(@scalar_structure, :load => [2])
        assert_equal(2, t1_.reduce_with_position{ |s_, v_, p_| flunk })
        assert_equal(5, t1_.reduce_with_position(3){ |s_, v_, p_| assert_equal([], p_.coord_array); s_ + v_ })
      end


      def test_1d_reduce
        t1_ = Table.new(@structure_1d, :load => (2..11).to_a)
        assert_equal(65, t1_.reduce(:+))
        assert_equal(165, t1_.reduce(100, :+))
        assert_equal(65, t1_.reduce{ |s_, v_| s_ + v_ })
        assert_equal(165, t1_.reduce(100){ |s_, v_| s_ + v_ })
      end


      def test_1d_reduce_with_position
        t1_ = Table.new(@structure_1d, :load => (2..11).to_a)
        label_ = 2
        val_ = t1_.reduce_with_position do |s_, v_, p_|
          assert_equal([label_], p_.coord_array)
          label_ += 1
          s_ + v_
        end
        assert_equal(65, val_)
        label_ = 1
        val_ = t1_.reduce_with_position(100) do |s_, v_, p_|
          assert_equal([label_], p_.coord_array)
          label_ += 1
          s_ + v_
        end
        assert_equal(165, val_)
      end


      def test_2d_reduce
        t1_ = Table.new(@structure_2d, :load => (2..21).to_a)
        assert_equal(230, t1_.reduce(:+))
        assert_equal(330, t1_.reduce(100, :+))
        assert_equal(230, t1_.reduce{ |s_, v_| s_ + v_ })
        assert_equal(330, t1_.reduce(100){ |s_, v_| s_ + v_ })
      end


      def test_2d_reduce_with_position
        t1_ = Table.new(@structure_2d, :load => (2..21).to_a)
        label1_ = 'two'
        label2_ = 1
        val_ = t1_.reduce_with_position do |s_, v_, p_|
          assert_equal([label2_, label1_], p_.coord_array)
          if label1_ == 'one'
            label1_ = 'two'
          else
            label1_ = 'one'
            label2_ += 1
          end
          s_ + v_
        end
        assert_equal(230, val_)
        label1_ = 'one'
        label2_ = 1
        val_ = t1_.reduce_with_position(100) do |s_, v_, p_|
          assert_equal([label2_, label1_], p_.coord_array)
          if label1_ == 'one'
            label1_ = 'two'
          else
            label1_ = 'one'
            label2_ += 1
          end
          s_ + v_
        end
        assert_equal(330, val_)
      end


    end

  end
end
