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


  # A Structure describes all the dimensions of a table. It is
  # essentially an ordered list of named axes, along with some
  # meta-information, and it is capable of performing computations
  # such as determining how to look up data at a particular coordinate.
  #
  # Generally, you create a new empty structure, and then use the #add
  # method to define the axes.
  #
  # Once a Structure is used by a table, it is locked and cannot be
  # modified further. However, a Structure can be shared by multiple
  # tables.

  class Structure


    class AxisInfo  # :nodoc:

      def initialize(axis_, index_, name_, step_=nil)
        @axis = axis_
        @index = index_
        @name = name_
        @step = step_
      end

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


    # A coordinate into a table

    class Position

      def initialize(structure_, vector_)
        @structure = structure_
        @vector = vector_
        @offset = @coords = nil
      end


      def eql?(obj_)
        obj_.is_a?(Position) && obj_.structure.eql?(@structure) && obj_._offset.eql?(self._offset)
      end
      alias_method :==, :eql?


      attr_reader :structure

      def coord(axis_)
        ainfo_ = @structure.axis_info(axis_)
        ainfo_ ? _coords[ainfo_.index] : nil
      end
      alias_method :[], :coord

      def coord_array
        _coords.dup
      end

      def next
        v_ = @vector.dup
        @structure._inc_vector(v_) ? nil : Position.new(@structure, v_)
      end

      def prev
        v_ = @vector.dup
        @structure._dec_vector(v_) ? nil : Position.new(@structure, v_)
      end


      def _offset  # :nodoc:
        @offset ||= @structure._compute_offset_for_vector(@vector)
      end

      def _coords  # :nodoc:
        @coords ||= @structure._compute_coords_for_vector(@vector)
      end

    end


    # Create an empty Structure

    def initialize
      @indexes = []
      @names = {}
      @size = 1
      @locked = false
      @sparse = false
    end


    def initialize_copy(other_)  # :nodoc:
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


    # Create an unlocked copy of this structure that can be further
    # modified.

    def unlocked_copy
      copy_ = Structure.new
      @indexes.each{ |ai_| copy_.add(ai_.axis, ai_.name) }
      copy_
    end


    # Returns true if the two structures are equivalent, both in the
    # axes and in the offsets.

    def eql?(rhs_)
      rhs_.is_a?(Structure) && rhs_.instance_variable_get(:@indexes).eql?(@indexes)
    end


    # Returns true if the two structures are equivalent in the axes but
    # not necessarily in the offsets.

    def ==(rhs_)
      if rhs_.is_a?(Structure)
        rhs_indexes_ = rhs_.instance_variable_get(:@indexes)
        if rhs_indexes_.size == @indexes.size
          rhs_indexes_.each_with_index do |rhs_ai_, i_|
            lhs_ai_ = @indexes[i_]
            return false unless lhs_ai_.axis == rhs_ai_.axis && lhs_ai_.name == rhs_ai_.name
          end
          return true
        end
      end
      false
    end


    def add(axis_, name_=nil)
      raise StructureStateError, "Structure locked" if @locked
      name_ = name_ ? name_.to_s : nil
      ainfo_ = AxisInfo.new(axis_, @indexes.size, name_)
      @indexes << ainfo_
      @names[name_] = ainfo_ if name_
      @size *= axis_.size
      self
    end


    def remove(axis_)
      raise StructureStateError, "Structure locked" if @locked
      if (ainfo_ = axis_info(axis_))
        index_ = ainfo_.index
        @names.delete(ainfo_.name)
        @indexes.delete_at(index_)
        @indexes[index_..-1].each{ |ai_| ai_._dec_index }
        size_ = ainfo_.axis.size
        if size_ == 0
          @size = @indexes.inject(1){ |s_, ai_| s_ * ai_.axis.size }
        else
          @size /= size_
        end
      end
      self
    end


    def replace(axis_, naxis_=nil)
      raise StructureStateError, "Structure locked" if @locked
      if (ainfo_ = axis_info(axis_))
        osize_ = ainfo_.axis.size
        naxis_ ||= yield(ainfo_)
        ainfo_._set_axis = naxis_
        if osize_ == 0
          @size = @indexes.inject(1){ |size_, ai_| size_ * ai_.axis.size }
        else
          @size = @size / osize_ * naxis_.size
        end
      end
      self
    end


    def sparse?
      @sparse
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
      unless @locked
        @locked = true
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
      @locked
    end


    def size
      @size
    end


    def empty?
      @size == 0
    end


    def position(arg_)
      vector_ = _vector(arg_)
      vector_ ? Position.new(self, vector_) : nil
    end


    def to_json_array
      @indexes.map do |ai_|
        name_ = ai_.name
        axis_ = ai_.axis
        type_ = axis_.class.name
        if type_ =~ /^NTable::(\w+)Axis$/
          type_ = $1
          type_ = type_[0..0].downcase + type_[1..-1]
        end
        obj_ = {'type' => type_}
        obj_['name'] = name_ if name_
        axis_.to_json_object(obj_)
        obj_
      end
    end


    def from_json_array(array_)
      array_.each do |obj_|
        name_ = obj_['name']
        type_ = obj_['type'] || 'Empty'
        if type_ =~ /^([a-z])(.*)$/
          mod_ = ::NTable.const_get("#{$1.upcase}#{$2}Axis")
        else
          mod_ = ::Kernel
          type_.split('::').each do |t_|
            mod_ = mod_.const_get(t_)
          end
        end
        axis_ = mod_.allocate
        axis_.from_json_object(obj_)
        add(axis_, name_)
      end
      self
    end


    def _offset(arg_)
      raise StructureStateError, "Structure not locked" unless @locked
      return nil unless @size > 0
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


    def _vector(arg_)
      raise StructureStateError, "Structure not locked" unless @locked
      return nil unless @size > 0
      vec_ = ::Array.new(@indexes.size, 0)
      case arg_
      when ::Hash
        arg_.each do |k_, v_|
          if (ainfo_ = axis_info(k_))
            val_ = ainfo_.axis.label_to_index(v_)
            vec_[ainfo_.index] = val_ if val_
          end
        end
        vec_
      when ::Array
        arg_.each_with_index do |v_, i_|
          if (ainfo_ = @indexes[i_])
            val_ = ainfo_.axis.label_to_index(v_)
            vec_[i_] = val_ if val_
          end
        end
        vec_
      else
        nil
      end
    end


    def _compute_offset_for_vector(vector_)  # :nodoc:
      offset_ = 0
      vector_.each_with_index do |v_, i_|
        offset_ += v_ * @indexes[i_].step
      end
      offset_
    end


    def _compute_coords_for_vector(vector_)  # :nodoc:
      vector_.map.with_index do |v_, i_|
        @indexes[i_].axis.index_to_label(v_)
      end
    end


    def _inc_vector(vector_)  # :nodoc:
      (vector_.size - 1).downto(-1) do |i_|
        return true if i_ < 0
        v_ = vector_[i_] + 1
        if v_ >= @indexes[i_].axis.size
          vector_[i_] = 0
        else
          vector_[i_] = v_
          break
        end
      end
      false
    end


    def _dec_vector(vector_)  # :nodoc:
      (vector_.size - 1).downto(-1) do |i_|
        return true if i_ < 0
        v_ = vector_[i_] - 1
        if v_ < 0
          vector_[i_] = @indexes[i_].axis.size - 1
        else
          vector_[i_] = v_
          break
        end
      end
      false
    end


    def _copy_with(axes_, bool_)  # :nodoc:
      copy_ = Structure.new
      indexes_ = []
      names_ = {}
      size_ = 1
      @indexes.each do |ainfo_|
        if axes_.include?(ainfo_.index) == bool_
          nainfo_ = AxisInfo.new(ainfo_.axis, indexes_.size, ainfo_.name, ainfo_.step)
          indexes_ << nainfo_
          names_[ainfo_.name] = nainfo_
          size_ *= ainfo_.axis.size
        end
      end
      copy_.instance_variable_set(:@indexes, indexes_)
      copy_.instance_variable_set(:@names, names_)
      copy_.instance_variable_set(:@size, size_)
      copy_.instance_variable_set(:@locked, true)
      copy_.instance_variable_set(:@sparse, true)
      copy_
    end


    def _compute_position_coords(offset_)  # :nodoc:
      raise StructureStateError, "Structure not locked" unless @locked
      @indexes.map do |ainfo_|
        i_ = offset_ / ainfo_.step
        offset_ -= ainfo_.step * i_
        ainfo_.axis.index_to_label(i_)
      end
    end


    def self.add(axis_, name_=nil)
      self.new.add(axis_, name_)
    end


    def self.from_json_array(array_)
      self.new.from_json_array(array_)
    end


  end


end
