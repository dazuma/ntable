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


  # A Structure describes how a table is laid out: how many dimensions
  # it has, how large the table is in each of those dimensions, what the
  # axes are called, and how the coordinates are labeled/named. It is
  # essentially an ordered list of named axes, along with some
  # meta-information. A Structure is capable of performing computations
  # such as determining how to look up data at a particular coordinate.
  #
  # Generally, you create a new empty structure, and then use the #add
  # method to define the axes. Provide the axis by creating an axis
  # object (for example, an instance of IndexedAxis or LabeledAxis.)
  # You can also optionally provide a name for the axis.
  #
  # Once a Structure is used by a table, it is locked and cannot be
  # modified further. However, a Structure can be shared by multiple
  # tables.
  #
  # Many table operations (such as slice) automatically compute the
  # structure of the result.

  class Structure


    # A data structure that provides information about a particular
    # axis/dimension in a Structure. It provides access to the axis
    # object, as well as the axis's name (if any) and 0-based index
    # into the list of axes. You should never need to create an
    # AxisInfo yourself, but you can obtain one from Structure#axis.

    class AxisInfo

      def initialize(axis_, index_, name_, step_=nil)  # :nodoc:
        @axis_object = axis_
        @axis_index = index_
        @axis_name = name_
        @step = step_
      end


      # The underlying axis implementation
      attr_reader :axis_object

      # The 0-based index of this axis in the structure. i.e. the first,
      # most major axis has number 0.
      attr_reader :axis_index

      # The name of this axis in the structure as a string, or nil for
      # no name.
      attr_reader :axis_name

      attr_reader :step  # :nodoc:


      # Given a label object, return the corresponding 0-based integer index.
      # Returns nil if the label is not recognized.

      def index(label_)
        @axis_object.index(label_)
      end


      # Given a 0-based integer index, return the corresponding label object.
      # Returns nil if the index is out of bounds (i.e. is less than 0 or
      # greater than or equal to size.)

      def label(index_)
        @axis_object.label(index_)
      end


      # Return the number of rows along this axis.
      # An empty axis will return 0.

      def size
        @axis_object.size
      end


      def eql?(obj_)  # :nodoc:
        obj_.is_a?(AxisInfo) && @axis_object.eql?(obj_.axis_object) && @axis_name.eql?(obj_.axis_name)
      end
      alias_method :==, :eql?  # :nodoc:


      def _set_axis(axis_)  # :nodoc:
        @axis_object = axis_
      end

      def _set_step(step_)  # :nodoc:
        @step = step_
      end

      def _dec_index  # :nodoc:
        @axis_index -= 1
      end

    end


    # A coordinate into a table. This object is often provided during
    # iteration to indicate where you are in the iteration. You should
    # not need to create a Position object yourself.

    class Position

      def initialize(structure_, vector_)  # :nodoc:
        @structure = structure_
        @vector = vector_
        @offset = @coords = nil
      end


      def eql?(obj_)
        obj_.is_a?(Position) && obj_.structure.eql?(@structure) && obj_._offset.eql?(self._offset)
      end
      alias_method :==, :eql?

      attr_reader :structure  # :nodoc:


      # Returns the label of the coordinate along the given axis. The
      # axis may be provided by name or index.

      def coord(axis_)
        ainfo_ = @structure.axis(axis_)
        ainfo_ ? _coords[ainfo_.axis_index] : nil
      end
      alias_method :[], :coord


      # Returns an array of all coordinate labels along the axes in
      # order.

      def coord_array
        _coords.dup
      end


      # Returns the Position of the "next" cell in the table, or nil
      # if this is the last cell.

      def next
        v_ = @vector.dup
        @structure._inc_vector(v_) ? nil : Position.new(@structure, v_)
      end


      # Returns the Position of the "previous" cell in the table, or nil
      # if this is the first cell.

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


    # Create an empty Structure. An empty structure corresponds to a
    # table with no axes and a single value (i.e. a scalar). Generally,
    # you should add axes using the Structure#add method before using
    # the structure.

    def initialize
      @indexes = []
      @names = {}
      @size = 1
      @locked = false
      @parent = nil
    end


    def initialize_copy(other_)  # :nodoc:
      initialize
      other_.instance_variable_get(:@indexes).each do |ai_|
        ai_ = ai_.dup
        @indexes << ai_
        if (name_ = ai_.axis_name)
          @names[name_] = ai_
        end
      end
      @size = other_.size
    end


    # Create an unlocked copy of this structure that can be further
    # modified.

    def unlocked_copy
      copy_ = Structure.new
      @indexes.each{ |ai_| copy_.add(ai_.axis_object, ai_.axis_name) }
      copy_
    end


    # Returns true if the two structures are equivalent, both in the
    # axes and in the parentage. The structure of a shared slice is not
    # equivalent, in this sense, to the "same" structure created from
    # scratch, because the former is a subview of a larger structure
    # whereas the latter is not.

    def eql?(rhs_)
      rhs_.equal?(self) ||
        rhs_.is_a?(Structure) &&
        @parent.eql?(rhs_.instance_variable_get(:@parent)) &&
        @indexes.eql?(rhs_.instance_variable_get(:@indexes))
    end


    # Returns true if the two structures are equivalent in the axes but
    # not necessarily in the offsets. The structure of a shared slice
    # is equivalent, in this sense, to the "same" structure created from
    # scratch, even though one is a subview and the other is not.

    def ==(rhs_)
      if rhs_.equal?(self)
        true
      elsif rhs_.is_a?(Structure)
        rhs_indexes_ = rhs_.instance_variable_get(:@indexes)
        if rhs_indexes_.size == @indexes.size
          rhs_indexes_.each_with_index do |rhs_ai_, i_|
            lhs_ai_ = @indexes[i_]
            return false unless lhs_ai_.axis_object == rhs_ai_.axis_object && lhs_ai_.axis_name == rhs_ai_.axis_name
          end
          return true
        end
        false
      else
        false
      end
    end


    # Append an axis to the configuration of this structure. You must
    # provide the axis, as an object that duck-types EmptyAxis. You may
    # also provide an optional name string.

    def add(axis_, name_=nil)
      raise StructureStateError, "Structure locked" if @locked
      name_ = name_ ? name_.to_s : nil
      ainfo_ = AxisInfo.new(axis_, @indexes.size, name_)
      @indexes << ainfo_
      @names[name_] = ainfo_ if name_
      @size *= axis_.size
      self
    end


    # Remove the given axis from the configuration.
    # You may specify the axis by 0-based index, or by name string.
    # Raises UnknownAxisError if there is no such axis.

    def remove(axis_)
      raise StructureStateError, "Structure locked" if @locked
      ainfo_ = axis(axis_)
      unless ainfo_
        raise UnknownAxisError, "Unknown axis: #{axis_.inspect}"
      end
      index_ = ainfo_.axis_index
      @names.delete(ainfo_.axis_name)
      @indexes.delete_at(index_)
      @indexes[index_..-1].each{ |ai_| ai_._dec_index }
      size_ = ainfo_.size
      if size_ == 0
        @size = @indexes.inject(1){ |s_, ai_| s_ * ai_.size }
      else
        @size /= size_
      end
      self
    end


    # Replace the given axis already in the configuration, with the
    # given new axis. The old axis must be specified by 0-based index
    # or by name string. The new axis must be provided as an axis
    # object that duck-types EmptyAxis.
    #
    # Raises UnknownAxisError if the given old axis specification
    # does not match an actual axis.

    def replace(axis_, naxis_=nil)
      raise StructureStateError, "Structure locked" if @locked
      ainfo_ = axis(axis_)
      unless ainfo_
        raise UnknownAxisError, "Unknown axis: #{axis_.inspect}"
      end
      osize_ = ainfo_.size
      naxis_ ||= yield(ainfo_)
      ainfo_._set_axis(naxis_)
      if osize_ == 0
        @size = @indexes.inject(1){ |size_, ai_| size_ * ai_.size }
      else
        @size = @size / osize_ * naxis_.size
      end
      self
    end


    # Returns the parent structure if this is a sub-view into a larger
    # structure, or nil if not.

    def parent
      @parent
    end


    # Returns the number of axes/dimensions currently in this structure.

    def dim
      @indexes.size
    end


    # Returns true if this is a degenerate/scalar structure. That is,
    # if the dimension is 0.

    def degenerate?
      @indexes.size == 0
    end


    # Returns an array of AxisInfo objects representing all the axes
    # of this structure.

    def all_axes
      @indexes.dup
    end


    # Returns the AxisInfo object representing the given axis. The axis
    # must be specified by 0-based index or by name string. Returns nil
    # if there is no such axis.

    def axis(axis_)
      case axis_
      when ::Integer
        @indexes[axis_]
      else
        @names[axis_.to_s]
      end
    end


    # Lock this structure, preventing further modification. Generally,
    # this is done automatically when a structure is used by a table,
    # and you do not need to call it yourself.

    def lock!
      unless @locked
        @locked = true
        if @size > 0
          s_ = @size
          @indexes.each do |ainfo_|
            s_ /= ainfo_.size
            ainfo_._set_step(s_)
          end
        end
      end
      self
    end


    # Returns true if this structure has been locked.

    def locked?
      @locked
    end


    # Returns the number of cells in a table with this structure.

    def size
      @size
    end


    # Returns true if this structure implies an "empty" table, one with
    # no cells. This happens only if at least one of the axes has a
    # zero size.

    def empty?
      @size == 0
    end


    # Creates a Position object for the given argument. The argument
    # may be a hash of row labels by axis name, or it may be an array
    # of row labels for the axes in order.

    def position(arg_)
      vector_ = _vector(arg_)
      vector_ ? Position.new(self, vector_) : nil
    end


    # Create a new substructure of this structure. The new structure
    # has this structure as its parent, but includes only the given
    # axes, which can be provided as an array of axis names or indexes.

    def substructure_including(*axes_)
      _substructure(axes_.flatten, true)
    end


    # Create a new substructure of this structure. The new structure
    # has this structure as its parent, but includes all axes EXCEPT the
    # given axes, provided as an array of axis names or indexes.

    def substructure_omitting(*axes_)
      _substructure(axes_.flatten, false)
    end


    # Returns an array of objects representing the configuration of
    # this structure. Such an array can be serialized as JSON, and
    # used to replicate this structure using from_json_array.

    def to_json_array
      @indexes.map do |ai_|
        name_ = ai_.axis_name
        axis_ = ai_.axis_object
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


    # Use the given array to reconstitute a structure previously
    # serialized using Structure#to_json_array.

    def from_json_array(array_)
      if @indexes.size > 0
        raise StructureStateError, "There are already axes in this structure"
      end
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


    # Create a new table using this structure as the structure.
    # Note that this also has the side effect of locking this structure.
    #
    # You can initialize the data using the following options:
    #
    # [<tt>:fill</tt>]
    #   Fill all cells with the given value.
    # [<tt>:load</tt>]
    #   Load the cell data with the values from the given array, in order.

    def create(data_={})
      Table.new(self, data_)
    end


    def _substructure(axes_, bool_)  # :nodoc:
      raise StructureStateError, "Structure not locked" unless @locked
      sub_ = Structure.new
      indexes_ = []
      names_ = {}
      size_ = 1
      @indexes.each do |ainfo_|
        if axes_.include?(ainfo_.axis_index) == bool_
          nainfo_ = AxisInfo.new(ainfo_.axis_object, indexes_.size, ainfo_.axis_name, ainfo_.step)
          indexes_ << nainfo_
          names_[ainfo_.axis_name] = nainfo_
          size_ *= ainfo_.size
        end
      end
      sub_.instance_variable_set(:@indexes, indexes_)
      sub_.instance_variable_set(:@names, names_)
      sub_.instance_variable_set(:@size, size_)
      sub_.instance_variable_set(:@locked, true)
      sub_.instance_variable_set(:@parent, self)
      sub_
    end


    def _offset(arg_)  # :nodoc:
      raise StructureStateError, "Structure not locked" unless @locked
      return nil unless @size > 0
      case arg_
      when ::Hash
        offset_ = 0
        arg_.each do |k_, v_|
          if (ainfo_ = axis(k_))
            index_ = ainfo_.index(v_)
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
            index_ = ainfo_.index(v_)
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


    def _vector(arg_)  # :nodoc:
      raise StructureStateError, "Structure not locked" unless @locked
      return nil unless @size > 0
      vec_ = ::Array.new(@indexes.size, 0)
      case arg_
      when ::Hash
        arg_.each do |k_, v_|
          if (ainfo_ = axis(k_))
            val_ = ainfo_.index(v_)
            vec_[ainfo_.axis_index] = val_ if val_
          end
        end
        vec_
      when ::Array
        arg_.each_with_index do |v_, i_|
          if (ainfo_ = @indexes[i_])
            val_ = ainfo_.index(v_)
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
        @indexes[i_].label(v_)
      end
    end


    def _inc_vector(vector_)  # :nodoc:
      (vector_.size - 1).downto(-1) do |i_|
        return true if i_ < 0
        v_ = vector_[i_] + 1
        if v_ >= @indexes[i_].size
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
          vector_[i_] = @indexes[i_].size - 1
        else
          vector_[i_] = v_
          break
        end
      end
      false
    end


    def _compute_position_coords(offset_)  # :nodoc:
      raise StructureStateError, "Structure not locked" unless @locked
      @indexes.map do |ainfo_|
        i_ = offset_ / ainfo_.step
        offset_ -= ainfo_.step * i_
        ainfo_.label(i_)
      end
    end


    class << self


      # Create a new structure and automatically add the given axis.
      # See Structure#add.

      def add(axis_, name_=nil)
        self.new.add(axis_, name_)
      end


      # Deserialize a structure from the given JSON array

      def from_json_array(array_)
        self.new.from_json_array(array_)
      end


    end


  end


end
