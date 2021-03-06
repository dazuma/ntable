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


require 'minitest/autorun'
require 'ntable'


module NTable
  module Tests  # :nodoc:

    class TestBasicValues < ::MiniTest::Unit::TestCase  # :nodoc:


      def setup
        @labeled_axis = LabeledAxis.new([:red, :white, :blue])
        @indexed_axis = IndexedAxis.new(10)
        @indexed_axis_1 = IndexedAxis.new(10, 1)
        @structure = Structure.add(@indexed_axis, :row).add(@labeled_axis, :column)
        @structure_1 = Structure.add(@indexed_axis_1, :row).add(@labeled_axis, :column)
      end


      def test_fill
        table_ = Table.new(@structure, :fill => 1)
        assert_equal(1, table_.get(0, :red))
        assert_equal(1, table_.get(5, :blue))
      end


      def test_load_and_get_from_array
        table_ = Table.new(@structure, :load => (0..29).to_a)
        assert_equal(0, table_.get(0, :red))
        assert_equal(17, table_.get(5, :blue))
      end


      def test_load_and_get_from_hash
        table_ = Table.new(@structure, :load => (0..29).to_a)
        assert_equal(0, table_.get(:row => 0, :column => :red))
        assert_equal(17, table_.get(:row => 5, :column => :blue))
      end


      def test_load_bang
        table_ = Table.new(@structure)
        table_.load!((0..16).to_a)
        assert_equal(0, table_.get(0, :red))
        assert_equal(16, table_.get(5, :white))
        assert_nil(table_.get(5, :blue))
      end


      def test_load_and_get_indexes
        table_ = Table.new(@structure_1, :load => (0..29).to_a)
        assert_equal(14, table_.get(5, 2))
        assert_equal(14, table_.get(0 => 5, 1 => 2))
        assert_equal(17, table_.get(::NTable.index(5), 2))
        assert_equal(17, table_.get(0 => ::NTable.index(5), 1 => 2))
      end


      def test_set_from_array
        table_ = Table.new(@structure)
        table_.set!(0, :red, "foo")
        table_[5, :blue] = "bar"
        assert_equal("foo", table_.get(0, :red))
        assert_equal("bar", table_[5, :blue])
        assert_nil(table_.get(5, :white))
      end


      def test_set_from_hash
        table_ = Table.new(@structure)
        table_.set!({:row => 0, :column => :red}, "foo")
        table_[:column => :blue, :row => 5] = "bar"
        assert_equal("foo", table_.get(0, :red))
        assert_equal("bar", table_[5, :blue])
        assert_nil(table_.get(5, :white))
      end


      def test_set_indexes
        table_ = Table.new(@structure_1)
        table_.set!(1, 1, "foo")
        table_[1 => 2, 0 => ::NTable.index(5)] = "bar"
        assert_equal("foo", table_.get(::NTable.index(0), :white))
        assert_equal("bar", table_[6, :blue])
        assert_nil(table_.get(5, :blue))
      end


      def test_load_no_axes
        t1_ = Table.new(Structure.new, :load => [1])
        assert_equal(1, t1_.get)
      end


      def test_empty_equality
        assert_equal(Table.new(Structure.new), Table.new(Structure.new))
      end


      def test_basic_equality
        t1_ = Table.new(@structure, :fill => 0)
        t2_ = Table.new(@structure, :fill => 0)
        assert_equal(t1_, t2_)
        t1_[:row => 0, :column => :red] = 1
        refute_equal(t1_, t2_)
        t2_[:row => 0, :column => :red] = 1
        assert_equal(t1_, t2_)
      end


      def test_convenience_construction
        t_ = NTable.structure(@indexed_axis, :row).add(@labeled_axis, :column).create(:fill => 1)
        assert_equal(1, t_.get(0, :red))
      end


      def test_include_p
        t1_ = Table.new(@structure, :fill => 0)
        assert_equal(true, t1_.include?(0, :red))
        assert_equal(true, t1_.include?(9, :blue))
        assert_equal(false, t1_.include?(10, :red))
        assert_equal(false, t1_.include?(0, :black))
      end


      def test_no_such_cell
        t1_ = Table.new(@structure, :fill => 0)
        assert_raises(NoSuchCellError) do
          t1_[10, :red]
        end
        assert_raises(NoSuchCellError) do
          t1_[0, :black]
        end
      end


    end

  end
end
