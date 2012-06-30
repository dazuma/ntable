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

    class TestBasicValues < ::Test::Unit::TestCase  # :nodoc:


      def setup
        @labeled_axis = LabeledAxis.new([:red, :white, :blue])
        @indexed_axis = IndexedAxis.new(10)
        @structure = Structure.new.add(@indexed_axis, :row).add(@labeled_axis, :column)
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
        assert_not_equal(t1_, t2_)
        t2_[:row => 0, :column => :red] = 1
        assert_equal(t1_, t2_)
      end


    end

  end
end
