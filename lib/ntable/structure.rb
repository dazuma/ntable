# -----------------------------------------------------------------------------
#
# NTable structure object
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


module NTable


  # Structure object

  class Structure


    class AxisInfo

      def initialize(structure_, axis_, index_, name_)
        @structure = structure_
        @axis = axis_
        @index = index_
        @name = name_
        @step = nil
      end

      attr_reader :structure
      attr_reader :axis
      attr_reader :index
      attr_reader :name
      attr_reader :step


      def eql?(obj_)
        obj_.is_a?(AxisInfo) && obj_.axis.eql?(@axis) && obj_.name.eql?(@name)
      end
      alias_method :==, :eql?


      def _set_axis(axis_)  # :nodoc:
        @axis = axis_
      end

      def _set_step(step_)  # :nodoc:
        @step = step_
      end

      def _dec_index  # :nodoc:
        @index -= 1
      end

    end


    class Position

      def initialize(structure_, offset_)
        @structure = structure_
        @offset = offset_
        @coords = offset_ < 0 || offset_ >= structure_.size ? false : nil
      end


      def eql?(obj_)
        obj_.is_a?(Position) && obj_.structure.eql?(@structure) && obj_.offset.eql?(@offset)
      end
      alias_method :==, :eql?


      attr_reader :structure
      attr_reader :offset

      def valid?
        @coords != false
      end

      def coord(axis_)
        @coords = @structure._compute_position_coords(@offset) if @coords.nil?
        ainfo_ = @structure.axis_info(axis_)
        ainfo_ ? @coords[ainfo_.index] : nil
      end
      alias_method :[], :coord

      def next
        pos_ = Position.new(@structure, @offset + 1)
        pos_.valid? ? pos_ : nil
      end

      def prev
        pos_ = Position.new(@structure, @offset - 1)
        pos_.valid? ? pos_ : nil
      end

    end


    def initialize
      @indexes = []
      @names = {}
      @size = nil
    end


    def initialize_copy(other_)
      initialize
      other_.instance_variable_get(:@indexes).each do |ai_|
        ai_ = ai_.dup
        @indexes << ai_
        if (name_ = ai_.name)
          @names[name_] = ai_
        end
      end
      @size = other_.size
    end


    def unlocked_copy
      copy_ = Structure.new
      @indexes.each{ |ai_| copy_.add(ai_.axis, ai_.name) }
      copy_
    end


    def eql?(obj_)
      obj_.is_a?(Structure) && obj_.instance_variable_get(:@indexes).eql?(@indexes)
    end
    alias_method :==, :eql?


    def add(axis_, name_=nil)
      raise StructureStateError, "Structure locked" if @size
      name_ = name_ ? name_.to_s : nil
      ainfo_ = AxisInfo.new(self, axis_, @indexes.size, name_)
      @indexes << ainfo_
      @names[name_] = ainfo_ if name_
      self
    end


    def remove(axis_)
      raise StructureStateError, "Structure locked" if @size
      if (ainfo_ = axis_info(axis_))
        index_ = ainfo_.index
        @names.delete(ainfo_.name)
        @indexes.delete_at(index_)
        @indexes[index_..-1].each{ |ai_| ai_._dec_index }
      end
      self
    end


    def replace(axis_, naxis_=nil)
      raise StructureStateError, "Structure locked" if @size
      if (ainfo_ = axis_info(axis_))
        naxis_ ||= yield(ainfo_)
        ainfo_._set_axis = naxis_
      end
      self
    end


    def dim
      @indexes.size
    end


    def degenerate?
      @indexes.size == 0
    end


    def all_axis_info
      @indexes.dup
    end


    def axis_info(axis_)
      case axis_
      when ::Integer
        @indexes[axis_]
      else
        @names[axis_.to_s]
      end
    end


    def get_axis(axis_)
      ainfo_ = axis_info(axis_)
      ainfo_ ? ainfo_.axis : nil
    end


    def get_index(axis_)
      ainfo_ = axis_info(axis_)
      ainfo_ ? ainfo_.index : nil
    end


    def get_name(axis_)
      ainfo_ = axis_info(axis_)
      ainfo_ ? ainfo_.name : nil
    end


    def lock!
      unless @size
        @size = @indexes.inject(1){ |size_, ainfo_| size_ * ainfo_.axis.size }
        if @size > 0
          s_ = @size
          @indexes.each do |ainfo_|
            s_ /= ainfo_.axis.size
            ainfo_._set_step(s_)
          end
        end
      end
      self
    end


    def locked?
      @size ? true : false
    end


    def size
      raise StructureStateError, "Structure not locked" unless @size
      @size
    end


    def empty?
      raise StructureStateError, "Structure not locked" unless @size
      @size == 0
    end


    def offset(arg_)
      return nil unless @size.to_i > 0
      case arg_
      when ::Hash
        offset_ = 0
        arg_.each do |k_, v_|
          if (ainfo_ = axis_info(k_))
            index_ = ainfo_.axis.label_to_index(v_)
            return nil unless index_
            offset_ += ainfo_.step * index_
          else
            return nil
          end
        end
        offset_
      when ::Array
        offset_ = 0
        arg_.each_with_index do |v_, i_|
          if (ainfo_ = @indexes[i_])
            index_ = ainfo_.axis.label_to_index(v_)
            return nil unless index_
            offset_ += ainfo_.step * index_
          else
            return nil
          end
        end
        offset_
      else
        nil
      end
    end


    def position(arg_)
      offset_ = offset(arg_)
      offset_ ? Position.new(self, offset_) : nil
    end


    def _compute_position_coords(offset_)  # :nodoc:
      raise "Structure not locked" unless @size
      @indexes.map do |ainfo_|
        i_ = offset_ / ainfo_.step
        offset_ -= ainfo_.step * i_
        ainfo_.axis.index_to_label(i_)
      end
    end


    def self.add(axis_, name_=nil)
      self.new.add(axis_, name_)
    end


  end


end
