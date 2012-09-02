# -----------------------------------------------------------------------------
#
# NTable table value object
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


require 'json'


module NTable


  # An N-dimensional table object, comprising structure and values.

  class Table


    # Create a table with the given structure.
    #
    # You can initialize the data using the following hash keys:
    #
    # [<tt>:fill</tt>]
    #   Fill all cells with the given value.
    # [<tt>:load</tt>]
    #   Load the cell data with the values from the given array, in order.

    def initialize(structure_, data_={})
      @structure = structure_
      @structure.lock!
      size_ = @structure.size
      if (load_ = data_[:load])
        load_size_ = load_.size
        if load_size_ > size_
          @vals = load_[0, size_]
        elsif load_size_ < size_
          @vals = load_ + ::Array.new(size_ - load_size_, data_[:fill])
        else
          @vals = load_.dup
        end
      elsif (acquire_ = data_[:acquire])
        @vals = acquire_
      else
        @vals = ::Array.new(size_, data_[:fill])
      end
      @offset = data_[:offset].to_i
      @parent = data_[:parent]
    end


    def initialize_copy(other_)  # :nodoc:
      if other_.parent
        @structure = other_.structure.unlocked_copy
        @structure.lock!
        @vals = other_._compacted_vals
        @offset = 0
        @parent = nil
      else
        initialize(other_.structure, :load => other_.instance_variable_get(:@vals))
      end
    end


    # Returns true if the two tables are equivalent, both in the data
    # and in the parentage. The structure of a shared slice is not
    # equivalent, in this sense, to the "same" table created from
    # scratch, because the former is a "sparse" subset of a parent
    # whereas the latter is not.

    def eql?(rhs_)
      self.equal?(rhs_) ||
        rhs_.is_a?(Table) &&
        @structure.eql?(rhs_.structure) && @parent.eql?(rhs_.parent) &&
        rhs_.instance_variable_get(:@offset) == @offset &&
        rhs_.instance_variable_get(:@vals).eql?(@vals)
    end


    # Returns true if the two tables are equivalent in data but not
    # necessarily parentage. The structure of a shared slice may be
    # equivalent, in this sense, to the "same" table created from
    # scratch with no parent.

    def ==(rhs_)
      if self.equal?(rhs_)
        true
      elsif rhs_.is_a?(Table)
        if rhs_.parent || self.parent
          if @structure == rhs_.structure
            riter_ = rhs_.each
            liter_ = self.each
            @structure.size.times do
              return false unless liter_.next == riter_.next
            end
            true
          else
            false
          end
        else
          rhs_.structure.eql?(@structure) && rhs_.instance_variable_get(:@vals).eql?(@vals)
        end
      else
        false
      end
    end


    # The Structure of this table
    attr_reader :structure


    # The number of cells in this table.

    def size
      @structure.size
    end


    # The number of dimensions/axes in this table.

    def dim
      @structure.dim
    end


    # True if this table has no cells.

    def empty?
      @structure.empty?
    end


    # True if this is a degenerate (scalar) table with a single cell
    # and no dimensions.

    def degenerate?
      @structure.degenerate?
    end


    # Return the parent of this table. A table with a parent shares the
    # parent's data, and cannot have its data modified directly. Instead,
    # if the parent table is modified, the changes are reflected in the
    # child. Returns nil if this table has no parent.

    def parent
      @parent
    end


    # Returns the value in the cell at the given coordinates, which
    # must be given as labels.
    # You may specify the cell as an array of coordinates, or as a
    # hash mapping axis name to coordinate.
    #
    # For example, for a typical database result set with an axis called
    # "row" of numerically identified rows, and an axis called "col" with
    # string-named columns, these call sequences are equivalent:
    #
    #  get(3, 'name')
    #  get([3, 'name'])
    #  get(:row => 3, :col => 'name')

    def get(*args_)
      if args_.size == 1
        first_ = args_.first
        args_ = first_ if first_.is_a?(::Hash) || first_.is_a?(::Array)
      end
      offset_ = @structure._offset(args_)
      offset_ ? @vals[@offset + offset_] : nil
    end
    alias_method :[], :get


    # Set the value in the cell at the given coordinates. If a block is
    # given, it is passed the current value and expects the new value
    # to be its result. If no block is given, the last argument is taken
    # to be the new value. The remaining arguments identify the cell,
    # using the same syntax as for Table#get.
    #
    # You cannot set a value in a table with a parent. Instead, you must
    # modify the parent, and those changes will be reflected in the child.

    def set!(*args_, &block_)
      raise TableLockedError if @parent
      value_ = block_ ? nil : args_.pop
      if args_.size == 1
        first_ = args_.first
        args_ = first_ if first_.is_a?(::Hash) || first_.is_a?(::Array)
      end
      offset_ = @structure._offset(args_)
      if offset_
        if block_
          value_ = block_.call(@vals[@offset + offset_])
        end
        @vals[@offset + offset_] = value_
      else
        @missing_value
      end
    end
    alias_method :[]=, :set!


    # Load an array of values into the table cells, in order.
    #
    # You cannot load values into a table with a parent. Instead, you must
    # modify the parent, and those changes will be reflected in the child.

    def load!(vals_)
      raise TableLockedError if @parent
      is_ = vals_.size
      vs_ = @vals.size
      if is_ < vs_
        @vals = vals_.dup + @vals[is_..-1]
      elsif is_ > vs_
        @vals = vals_[0,vs_]
      else
        @vals = vals_.dup
      end
    end


    # Fill all table cells with the given value.
    #
    # You cannot load values into a table with a parent. Instead, you must
    # modify the parent, and those changes will be reflected in the child.

    def fill!(value_)
      raise TableLockedError if @parent
      @vals.fill(value_)
    end


    # Iterate over all table cells, in order, and call the given block.
    # If no block is given, an ::Enumerator is returned.

    def each(&block_)
      if @parent
        if block_given?
          vec_ = ::Array.new(@structure.dim, 0)
          @structure.size.times do
            yield(@vals[@offset + @structure._compute_offset_for_vector(vec_)])
            @structure._inc_vector(vec_)
          end
        else
          enum_for
        end
      else
        @vals.each(&block_)
      end
    end


    # Iterate over all table cells, and call the given block with the
    # value and the Structure::Position for the cell.

    def each_with_position
      vec_ = ::Array.new(@structure.dim, 0)
      @structure.size.times do
        yield(@vals[@offset + @structure._compute_offset_for_vector(vec_)],
          Structure::Position.new(@structure, vec_))
        @structure._inc_vector(vec_)
      end
      self
    end


    # Return a new table whose structure is the same as this table, and
    # whose values are given by mapping the current table's values through
    # the given block.

    def map(&block_)
      if @parent
        vec_ = ::Array.new(@structure.dim, 0)
        nvals_ = (0...@structure.size).map do |i_|
          val_ = yield(@vals[@offset + @structure._compute_offset_for_vector(vec_)])
          @structure._inc_vector(vec_)
          val_
        end
        Table.new(@structure.unlocked_copy, :acquire => nvals_)
      else
        Table.new(@structure, :acquire => @vals.map(&block_))
      end
    end


    # Same as Table#map except the block is passed the current table's
    # value for each cell, and the cell's Structure::Position.

    def map_with_position
      nstructure_ = @structure.parent ? @structure.unlocked_copy : @structure
      vec_ = ::Array.new(@structure.dim, 0)
      nvals_ = (0...@structure.size).map do |i_|
        nval_ = yield(@vals[@offset + @structure._compute_offset_for_vector(vec_)],
          Structure::Position.new(@structure, vec_))
        @structure._inc_vector(vec_)
        nval_
      end
      Table.new(nstructure_, :acquire => nvals_)
    end


    # Modify the current table in place, mapping values through the given
    # block.
    #
    # You cannot set values in a table with a parent. Instead, you must
    # modify the parent, and those changes will be reflected in the child.

    def map!(&block_)
      raise TableLockedError if @parent
      @vals.map!(&block_)
      self
    end


    # Modify the current table in place, mapping values through the given
    # block, which takes both the old value and the Structure::Position.
    #
    # You cannot set values in a table with a parent. Instead, you must
    # modify the parent, and those changes will be reflected in the child.

    def map_with_position!
      raise TableLockedError if @parent
      vec_ = ::Array.new(@structure.dim, 0)
      @vals.map! do |val_|
        nval_ = yield(val_, Structure::Position.new(@structure, vec_))
        @structure._inc_vector(vec_)
        nval_
      end
      self
    end


    # Performs a reduce on the entire table and returns the result.

    def reduce(*args_)
      nothing_ = ::Object.new
      if block_given?
        case args_.size
        when 1
          obj_ = args_.first
        when 0
          obj_ = nothing_
        else
          raise ::ArgumentError, "Wrong number of arguments"
        end
        each do |e_|
          if nothing_ == obj_
            obj_ = e_
          else
            obj_ = yield(obj_, e_)
          end
        end
      else
        sym_ = args_.pop
        case args_.size
        when 1
          obj_ = args_.first
        when 0
          obj_ = nothing_
        else
          raise ::ArgumentError, "Wrong number of arguments"
        end
        each do |e_|
          if nothing_ == obj_
            obj_ = e_
          else
            obj_ = obj_.send(sym_, e_)
          end
        end
      end
      nothing_ == obj_ ? nil : obj_
    end
    alias_method :inject, :reduce


    # Performs a reduce on the entire table and returns the result.

    def reduce_with_position(*args_)
      nothing_ = ::Object.new
      case args_.size
      when 1
        obj_ = args_.first
      when 0
        obj_ = nothing_
      else
        raise ::ArgumentError, "Wrong number of arguments"
      end
      each_with_position do |val_, pos_|
        if nothing_ == obj_
          obj_ = val_
        else
          obj_ = yield(obj_, val_, pos_)
        end
      end
      nothing_ == obj_ ? nil : obj_
    end
    alias_method :inject_with_position, :reduce_with_position


    # Decomposes this table, breaking it into a set of lower-dimensional
    # tables, all arranged in a table. For example, you could decompose
    # a two-dimensional table into a one-dimensional table OF one-dimensional
    # tables. The axes of the lower-dimensional tables are called the
    # "inner" axes. You must specify the inner axes as an array of
    # axis specifications (indexes or names).

    def decompose(*axes_)
      axes_ = axes_.flatten
      axis_indexes_ = []
      axes_.each do |a_|
        if (ainfo_ = @structure.axis_info(a_))
          axis_indexes_ << ainfo_.index
        else
          raise UnknownAxisError, "Unknown axis: #{a_.inspect}"
        end
      end
      inner_struct_ = @structure.substructure_including(axis_indexes_)
      outer_struct_ = @structure.substructure_omitting(axis_indexes_)
      vec_ = ::Array.new(outer_struct_.dim, 0)
      tables_ = (0...outer_struct_.size).map do |i_|
        t_ = Table.new(inner_struct_, :acquire => @vals,
          :offset => outer_struct_._compute_offset_for_vector(vec_),
          :parent => self)
        outer_struct_._inc_vector(vec_)
        t_
      end
      Table.new(outer_struct_.unlocked_copy, :acquire => tables_)
    end


    def decompose_reduce(decompose_axes_, *reduce_args_, &block_)
      decompose(decompose_axes_).map{ |sub_| sub_.reduce(*reduce_args_, &block_) }
    end


    def decompose_reduce_with_position(decompose_axes_, *reduce_args_, &block_)
      decompose(decompose_axes_).map{ |sub_| sub_.reduce_with_position(*reduce_args_, &block_) }
    end


    def shared_slice(hash_)
      offset_ = @offset
      select_set_ = {}
      hash_.each do |k_, v_|
        if (ainfo_ = @structure.axis_info(k_))
          aindex_ = ainfo_.index
          unless select_set_.include?(aindex_)
            lindex_ = ainfo_.axis.label_to_index(v_)
            if lindex_
              offset_ += ainfo_.step * lindex_
              select_set_[aindex_] = true
            end
          end
        end
      end
      Table.new(@structure.substructure_omitting(select_set_.keys),
        :acquire => @vals, :offset => offset_, :parent => self)
    end


    def slice(hash_)
      shared_slice(hash_).dup
    end


    def to_json_object
      {'type' => 'ntable', 'axes' => @structure.to_json_array, 'values' => @parent ? _compacted_vals : @vals}
    end


    def to_json
      to_json_object.to_json
    end


    def to_nested_object(opts_={})
      if @structure.degenerate?
        @vals[@offset]
      else
        _to_nested_obj(0, ::Array.new(@structure.dim, 0), opts_)
      end
    end


    def _to_nested_obj(aidx_, vec_, opts_)  # :nodoc:
      exclude_ = opts_.include?(:exclude_value)
      exclude_value_ = opts_[:exclude_value] if exclude_
      axis_ = @structure.axis_info(aidx_).axis
      result_ = IndexedAxis === axis_ ? [] : {}
      (0...axis_.size).map do |i_|
        vec_[aidx_] = i_
        val_ = if aidx_ + 1 == vec_.size
          @vals[@offset + @structure._compute_offset_for_vector(vec_)]
        else
          _to_nested_obj(aidx_ + 1, vec_, opts_)
        end
        if !exclude_ || !val_.eql?(exclude_value_)
          result_[axis_.index_to_label(i_)] = val_
        end
      end
      result_
    end


    def _compacted_vals  # :nodoc:
      vec_ = ::Array.new(@structure.dim, 0)
      ::Array.new(@structure.size) do
        val_ = @vals[@offset + @structure._compute_offset_for_vector(vec_)]
        @structure._inc_vector(vec_)
        val_
      end
    end


    @numeric_sort = ::Proc.new{ |a_, b_| a_.to_f <=> b_.to_f }


    class << self


      def from_json_object(json_)
        new(Structure.from_json_array(json_['axes'] || []), :load => json_['values'] || [])
      end


      def parse_json(json_)
        from_json_object(::JSON.parse(json_))
      end


      def from_nested_object(obj_, field_opts_=[], opts_={})
        axis_data_ = []
        _populate_nested_axes(axis_data_, 0, obj_)
        struct_ = Structure.new
        axis_data_.each_with_index do |ai_, i_|
          field_ = field_opts_[i_] || {}
          axis_ = nil
          name_ = field_[:name]
          case ai_
          when ::Hash
            labels_ = ai_.keys
            if (sort_ = field_[:sort])
              if sort_.respond_to?(:call)
                func_ = sort_
              elsif sort_ == :numeric
                func_ = @numeric_sort
              else
                func_ = nil
              end
              labels_.sort!(&func_)
            end
            if (xform_ = field_[:transform])
              labels_.map!(&xform_)
            end
            axis_ = LabeledAxis.new(labels_)
          when ::Array
            axis_ = IndexedAxis.new(ai_[1].to_i - ai_[0].to_i, ai_[0].to_i)
          end
          struct_.add(axis_, name_) if axis_
        end
        table_ = new(struct_, :fill => opts_[:fill])
        _populate_nested_values(table_, [], obj_)
        table_
      end


      def _populate_nested_axes(axis_data_, index_, obj_)  # :nodoc:
        ai_ = axis_data_[index_]
        case obj_
        when ::Hash
          if ::Hash === ai_
            set_ = ai_
          else
            set_ = axis_data_[index_] = {}
            (ai_[0]...ai_[1]).each{ |i_| set_[i_.to_s] = true } if ::Array === ai_
          end
          obj_.each do |k_, v_|
            set_[k_.to_s] = true
            _populate_nested_axes(axis_data_, index_+1, v_)
          end
        when ::Array
          if ::Hash === ai_
            obj_.each_with_index do |v_, i_|
              ai_[i_.to_s] = true
              _populate_nested_axes(axis_data_, index_+1, v_)
            end
          else
            s_ = obj_.size
            if ::Array === ai_
              if s_ > 0
                ai_[1] = s_ if !ai_[1] || s_ > ai_[1]
                ai_[0] = s_ if !ai_[0]
              end
            else
              ai_ = axis_data_[index_] = (s_ == 0 ? [nil, nil] : [s_, s_])
            end
            obj_.each_with_index do |v_, i_|
              ai_[0] = i_ if ai_[0] > i_ && !v_.nil?
              _populate_nested_axes(axis_data_, index_+1, v_)
            end
          end
        end
      end


      def _populate_nested_values(table_, path_, obj_)  # :nodoc:
        if path_.size == table_.dim
          table_.set!(*path_, obj_)
        else
          case obj_
          when ::Hash
            obj_.each do |k_, v_|
              _populate_nested_values(table_, path_ + [k_.to_s], v_)
            end
          when ::Array
            obj_.each_with_index do |v_, i_|
              _populate_nested_values(table_, path_ + [i_], v_) unless v_.nil?
            end
          end
        end
      end


    end


  end


end
