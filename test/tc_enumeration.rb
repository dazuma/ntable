# -----------------------------------------------------------------------------
#
# Table enumeration (each/map) tests
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

    class TestEnumeration < ::MiniTest::Unit::TestCase  # :nodoc:


      def setup
        @labeled_axis_2 = LabeledAxis.new([:one, :two])
        @indexed_axis_10 = IndexedAxis.new(10,1)
        @indexed_axis_0 = IndexedAxis.new(0)
        @scalar_structure = Structure.new
        @structure_2d = Structure.add(@indexed_axis_10).add(@labeled_axis_2)
        @empty_structure = Structure.add(@indexed_axis_0)
      end


      def test_scalar_each
        t1_ = Table.new(@scalar_structure, :load => [:foo])
        size_ = 0
        t1_.each do |v_|
          assert_equal(:foo, v_)
          size_ += 1
        end
        assert_equal(1, size_)
      end


      def test_scalar_each_with_position
        t1_ = Table.new(@scalar_structure, :load => [:foo])
        size_ = 0
        t1_.each_with_position do |v_, p_|
          assert_equal(:foo, v_)
          assert_equal([], p_.coord_array)
          size_ += 1
        end
        assert_equal(1, size_)
      end


      def test_scalar_map
        t1_ = Table.new(@scalar_structure, :load => [1])
        t2_ = t1_.map do |v_|
          v_ * 2
        end
        assert_equal(2, t2_.get)
      end


      def test_scalar_map_with_position
        t1_ = Table.new(@scalar_structure, :load => [1])
        t2_ = t1_.map_with_position do |v_, p_|
          assert_equal([], p_.coord_array)
          v_ * 2
        end
        assert_equal(2, t2_.get)
      end


      def test_scalar_map_bang
        t1_ = Table.new(@scalar_structure, :load => [1])
        t1_.map! do |v_|
          v_ * 2
        end
        assert_equal(2, t1_.get)
      end


      def test_scalar_map_with_position_bang
        t1_ = Table.new(@scalar_structure, :load => [1])
        t1_.map_with_position! do |v_, p_|
          assert_equal([], p_.coord_array)
          v_ * 2
        end
        assert_equal(2, t1_.get)
      end


      def test_2d_each
        t1_ = Table.new(@structure_2d, :load => (2..21).to_a)
        size_ = 2
        t1_.each do |v_|
          assert_equal(size_, v_)
          size_ += 1
        end
        assert_equal(22, size_)
      end


      def test_2d_each_with_position
        t1_ = Table.new(@structure_2d, :load => (2..21).to_a)
        size_ = 2
        label1_ = 'one'
        label2_ = 1
        t1_.each_with_position do |v_, p_|
          assert_equal([label2_, label1_], p_.coord_array)
          assert_equal(size_, v_)
          size_ += 1
          if label1_ == 'one'
            label1_ = 'two'
          else
            label1_ = 'one'
            label2_ += 1
          end
        end
        assert_equal(22, size_)
      end


      def test_2d_map
        t1_ = Table.new(@structure_2d, :load => (2..21).to_a)
        t2_ = t1_.map do |v_|
          v_ * 2
        end
        assert_equal(4, t2_.get(1, :one))
        assert_equal(6, t2_.get(1, :two))
        assert_equal(42, t2_.get(10, :two))
      end


      def test_2d_map_with_position
        t1_ = Table.new(@structure_2d, :load => (2..21).to_a)
        label1_ = 'one'
        label2_ = 1
        t2_ = t1_.map_with_position do |v_, p_|
          assert_equal([label2_, label1_], p_.coord_array)
          if label1_ == 'one'
            label1_ = 'two'
          else
            label1_ = 'one'
            label2_ += 1
          end
          v_ * 2
        end
        assert_equal(4, t2_.get(1, :one))
        assert_equal(6, t2_.get(1, :two))
        assert_equal(42, t2_.get(10, :two))
      end


      def test_2d_map_bang
        t1_ = Table.new(@structure_2d, :load => (2..21).to_a)
        t1_.map! do |v_|
          v_ * 2
        end
        assert_equal(4, t1_.get(1, :one))
        assert_equal(6, t1_.get(1, :two))
        assert_equal(42, t1_.get(10, :two))
      end


      def test_2d_map_with_position_bang
        t1_ = Table.new(@structure_2d, :load => (2..21).to_a)
        label1_ = 'one'
        label2_ = 1
        t1_.map_with_position! do |v_, p_|
          assert_equal([label2_, label1_], p_.coord_array)
          if label1_ == 'one'
            label1_ = 'two'
          else
            label1_ = 'one'
            label2_ += 1
          end
          v_ * 2
        end
        assert_equal(4, t1_.get(1, :one))
        assert_equal(6, t1_.get(1, :two))
        assert_equal(42, t1_.get(10, :two))
      end


      def test_empty
        t1_ = Table.new(@empty_structure)
        t1_.each do |v_|
          flunk
        end
        t1_.each_with_position do |v_, p_|
          flunk
        end
        t1_.map do |v_|
          flunk
        end
        t1_.map_with_position do |v_, p_|
          flunk
        end
        t1_.map! do |v_|
          flunk
        end
        t1_.map_with_position! do |v_, p_|
          flunk
        end
        pass
      end


    end

  end
end
