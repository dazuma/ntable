# -----------------------------------------------------------------------------
#
# Table structure tests
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

    class TestStructure < ::MiniTest::Unit::TestCase  # :nodoc:


      def setup
        @labeled1 = LabeledAxis.new([:one, :two])
        @labeled2 = LabeledAxis.new([:red, :white, :blue])
        @indexed1 = IndexedAxis.new(10)
        @indexed2 = IndexedAxis.new(15, 1)
        @indexed3 = IndexedAxis.new(0)
      end


      def test_dim_for_various_adds
        s_ = Structure.new
        s_.add(@labeled1)
        assert_equal(1, s_.dim)
        s_.add(@indexed1)
        assert_equal(2, s_.dim)
        s_.add(@indexed1)
        assert_equal(3, s_.dim)
      end


      def test_add_single_axis
        s_ = Structure.new
        s_.add(@labeled1, :first)
        assert_equal(@labeled1, s_.get_axis(0))
        assert_equal(@labeled1, s_.get_axis(:first))
        assert_equal(0, s_.get_index(:first))
        assert_equal('first', s_.get_name(0))
      end


      def test_add_multi_axis
        s_ = Structure.new
        s_.add(@labeled1, :first)
        s_.add(@indexed1, :second)
        s_.add(@indexed1)
        assert_equal(@labeled1, s_.get_axis(0))
        assert_equal(@labeled1, s_.get_axis(:first))
        assert_equal(0, s_.get_index(:first))
        assert_equal('first', s_.get_name(0))
        assert_equal(@indexed1, s_.get_axis(1))
        assert_equal(@indexed1, s_.get_axis(:second))
        assert_equal(1, s_.get_index(:second))
        assert_equal('second', s_.get_name(1))
        assert_equal(@indexed1, s_.get_axis(2))
        assert_nil(s_.get_name(2))
      end


      def test_remove_axis
        s_ = Structure.new
        s_.add(@labeled1, :first)
        s_.add(@indexed1, :second)
        s_.remove(:first)
        assert_equal(1, s_.dim)
        assert_equal(@indexed1, s_.get_axis(0))
        assert_equal(@indexed1, s_.get_axis(:second))
        assert_equal(0, s_.get_index(:second))
        assert_equal('second', s_.get_name(0))
        assert_nil(s_.get_name(1))
        assert_nil(s_.get_index(:first))
      end


      def test_lock
        s_ = Structure.new.add(@labeled1)
        assert_equal(false, s_.locked?)
        s_.lock!
        assert_equal(true, s_.locked?)
      end


      def test_size_1
        s_ = Structure.new.add(@labeled1).lock!
        assert_equal(2, s_.size)
      end


      def test_size_2
        s_ = Structure.new.add(@labeled1).add(@indexed1).add(@indexed2).lock!
        assert_equal(300, s_.size)
      end


      def test_size_no_axes
        s_ = Structure.new.lock!
        assert_equal(1, s_.size)
      end


      def test_size_with_empty_axis
        s_ = Structure.new.add(@labeled1).add(@indexed1).add(@indexed3).lock!
        assert_equal(0, s_.size)
      end


      def test_offset_labeled1_array
        s_ = Structure.new.add(@labeled1).lock!
        assert_equal(0, s_._offset([:one]))
        assert_equal(1, s_._offset([:two]))
        assert_nil(s_._offset([:three]))
      end


      def test_offset_labeled1_hash
        s_ = Structure.new.add(@labeled1, :first_label).lock!
        assert_equal(0, s_._offset(:first_label => :one))
        assert_equal(1, s_._offset(:first_label => :two))
        assert_nil(s_._offset(:first_label => :three))
        assert_nil(s_._offset(:second_label => :one))
      end


      def test_offset_labeled1_indexed1_array
        s_ = Structure.new.add(@labeled1).add(@indexed1).lock!
        assert_equal(2, s_._offset([:one, 2]))
        assert_equal(13, s_._offset([:two, 3]))
        assert_equal(10, s_._offset([:two]))
        assert_nil(s_._offset([:three, 0]))
      end


      def test_offset_labeled1_indexed1_hash
        s_ = Structure.new.add(@labeled1, :first_axis).add(@indexed1, :second_axis).lock!
        assert_equal(2, s_._offset(:first_axis => :one, :second_axis => 2))
        assert_equal(13, s_._offset(:first_axis => :two, :second_axis => 3))
        assert_equal(5, s_._offset(:second_axis => 5))
        assert_nil(s_._offset(:first_axis => :three))
        assert_nil(s_._offset(:third_axis => :three))
      end


      def test_offset_no_axes
        s_ = Structure.new.lock!
        assert_equal(0, s_._offset([]))
        assert_equal(0, s_._offset({}))
      end


      def test_empty_structure_equality
        assert_equal(Structure.new, Structure.new)
      end


      def test_structure_equality
        s1_ = Structure.new.add(@labeled1).add(@indexed1)
        s2_ = Structure.new.add(@labeled1).add(@indexed1)
        s3_ = Structure.new.add(@indexed1).add(@labeled1)
        assert_equal(s1_, s2_)
        refute_equal(s1_, s3_)
      end


    end

  end
end
