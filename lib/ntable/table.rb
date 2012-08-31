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


  # A table object.

  class Table


    def initialize(structure_, data_={})
      @structure = structure_
      @structure.lock!
      if (share_ = data_[:share])
        @vals = share_
        @offset = data_[:offset].to_i
        @shared = true
      else
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
        @offset = 0
        @shared = false
      end
    end


    def initialize_copy(other_)
      if other_.shared?
        @structure = other_.structure.unlocked_copy
        @structure.lock!
        @vals = other_._compacted_vals
        @offset = 0
        @shared = false
      else
        initialize(other_.structure, :load => other_.instance_variable_get(:@vals))
      end
    end


    def eql?(rhs_)
      rhs_.is_a?(Table) && rhs_.structure.eql?(@structure) &&
        rhs_.instance_variable_get(:@vals).eql?(@vals)
    end


    def ==(rhs_)
      if rhs_.is_a?(Table)
        if rhs_.shared? || self.shared?
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
      end
    end


    attr_reader :structure


    def size
      @structure.size
    end


    def dim
      @structure.dim
    end


    def empty?
      @structure.empty?
    end


    def degenerate?
      @structure.degenerate?
    end


    def shared?
      @shared
    end


    def get(*args_)
      if args_.size == 1
        first_ = args_.first
        args_ = first_ if first_.is_a?(::Hash) || first_.is_a?(::Array)
      end
      offset_ = @structure._offset(args_)
      offset_ ? @vals[@offset + offset_] : nil
    end
    alias_method :[], :get


    def set!(*args_, &block_)
      raise TableLockedError if @shared
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


    def load!(vals_)
      raise TableLockedError if @shared
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


    def fill!(value_)
      raise TableLockedError if @shared
      @vals.fill(value_)
    end


    def each(&block_)
      if @shared
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


    def each_with_position
      vec_ = ::Array.new(@structure.dim, 0)
      @structure.size.times do
        yield(@vals[@offset + @structure._compute_offset_for_vector(vec_)],
          Structure::Position.new(@structure, vec_))
        @structure._inc_vector(vec_)
      end
      self
    end


    def map(&block_)
      if @shared
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


    def map_with_position
      nstructure_ = @structure.sparse? ? @structure.unlocked_copy : @structure
      vec_ = ::Array.new(@structure.dim, 0)
      nvals_ = (0...@structure.size).map do |i_|
        nval_ = yield(@vals[@offset + @structure._compute_offset_for_vector(vec_)],
          Structure::Position.new(@structure, vec_))
        @structure._inc_vector(vec_)
        nval_
      end
      Table.new(nstructure_, :acquire => nvals_)
    end


    def map!(&block_)
      raise TableLockedError if @shared
      @vals.map!(&block_)
      self
    end


    def map_with_position!
      raise TableLockedError if @shared
      vec_ = ::Array.new(@structure.dim, 0)
      @vals.map! do |val_|
        nval_ = yield(val_, Structure::Position.new(@structure, vec_))
        @structure._inc_vector(vec_)
        nval_
      end
      self
    end


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


    # Returns a new table whose values are slices of this table,
    # containing all the original data. Effectively "partitions" the
    # dimensions of this table into axes on the "inner" tables and
    # axes on the "outer" table. You must pass the names or indexes
    # of the "inner" axes.

    def partition(axes_)
      axis_indexes_ = []
      axes_.each do |a_|
        if (ainfo_ = @structure.axis_info(a_))
          axis_indexes_ << ainfo_.index
        else
          raise UnknownAxisError, "Unknown axis: #{a_.inspect}"
        end
      end
      inner_struct_ = @structure._copy_with(axis_indexes_, true)
      outer_struct_ = @structure._copy_with(axis_indexes_, false)
      vec_ = ::Array.new(outer_struct_.dim, 0)
      tables_ = (0...outer_struct_.size).map do |i_|
        t_ = Table.new(inner_struct_, :share => @vals,
          :offset => outer_struct_._compute_offset_for_vector(vec_))
        outer_struct_._inc_vector(vec_)
        t_
      end
      Table.new(outer_struct_.unlocked_copy, :acquire => tables_)
    end


    def partition_reduce(axes_, *args_, &block_)
      partition(axes_).map{ |sub_| sub_.reduce(*args_, &block_) }
    end


    def partition_reduce_with_position(axes_, *args_, &block_)
      partition(axes_).map{ |sub_| sub_.reduce_with_position(*args_, &block_) }
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
      Table.new(@structure._copy_with(select_set_, false), :share => @vals, :offset => offset_)
    end


    def slice(hash_)
      shared_slice(hash_).dup
    end


    def concat(rhs_, axis_=nil)
      # Get axes
      my_ainfo_ = @structure.all_axis_info
      rhs_ainfo_ = rhs_.structure.all_axis_info
      unless my_ainfo_.size == rhs_ainfo_.size
        raise StructureMismatchError, "Tables have different dimensions"
      end

      # Determine the concatenated axis
      concat_index_ = concat_axis_ = concat_ainfo_ = nil
      if axis_
        concat_ainfo_ = @structure.axis_info(axis_)
        unless concat_ainfo_
          raise StructureMismatchError, "Unable to find specified concatenation axis: #{axis_}"
        end
        concat_index_ = concat_ainfo_.index
        concat_axis_ = concat_ainfo_.axis.concat(rhs_ainfo_[concat_index_].axis)
        unless concat_axis_
          raise StructureMismatchError, "Axes cannot be concatenated"
        end
      else
        my_ainfo_.each_with_index do |my_ai_, i_|
          rhs_ai_ = rhs_ainfo_[i_]
          unless my_ai_.axis.eql?(rhs_ai_.axis)
            concat_ainfo_ = my_ai_
            concat_index_ = i_
            concat_axis_ = my_ai_.axis.concat(rhs_ai_.axis)
            unless concat_axis_
              raise StructureMismatchError, "Axes cannot be concatenated"
            end
            break
          end
        end
        unless concat_axis_
          my_ainfo_.each_with_index do |my_ai_, i_|
            rhs_ai_ = rhs_ainfo_[i_]
            concat_axis_ = my_ai_.axis.concat(rhs_ai_.axis)
            if concat_axis_
              concat_ainfo_ = my_ai_
              concat_index_ = i_
              break
            end
          end
        end
        unless concat_axis_
          raise StructureMismatchError, "Unable to find an axis that can be concatenated"
        end
      end

      # Create the concatenated structure
      sum_structure_ = Structure.new
      my_ainfo_.each_with_index do |my_ai_, i_|
        rhs_ai_ = rhs_ainfo_[i_]
        unless my_ai_.name == rhs_ai_.name
          raise StructureMismatchError, "Axis #{i_} names do not match"
        end
        if concat_index_ == i_
          sum_structure_.add(concat_axis_, my_ai_.name)
        else
          unless my_ai_.axis.eql?(rhs_ai_.axis)
            raise StructureMismatchError, "Non-concatenating axes #{i_} are not equal"
          end
          sum_structure_.add(my_ai_.axis, my_ai_.name)
        end
      end

      # Copy the data, interleaved
      lhs_vals_ = @shared ? _compacted_vals : @vals
      rhs_vals_ = rhs_.shared? ? rhs_._compacted_vals : rhs_.instance_variable_get(:@vals)
      inner_step_ = concat_ainfo_.step
      lhs_step_ = concat_ainfo_.axis.size * inner_step_
      rhs_step_ = rhs_ainfo_[concat_index_].axis.size * inner_step_
      outer_size_ = @structure.size / lhs_step_
      sum_structure_.lock!
      sum_vals_ = ::Array.new(sum_structure_.size)
      sum_step_ = lhs_step_ + rhs_step_
      outer_size_.times do |i_|
        sum_vals_[i_*sum_step_,lhs_step_] = lhs_vals_[i_*lhs_step_,lhs_step_]
        sum_vals_[i_*sum_step_+lhs_step_,rhs_step_] = rhs_vals_[i_*rhs_step_,rhs_step_]
      end
      Table.new(sum_structure_, :acquire => sum_vals_)
    end
    alias_method :+, :concat


    def to_json_object
      {'type' => 'ntable', 'axes' => @structure.to_json_array, 'values' => @shared ? _compacted_vals : @vals}
    end


    def to_json
      to_json_object.to_json
    end


    def to_nested_object(opts_={})
      _to_nested_obj(0, ::Array.new(@structure.dim, 0), opts_)
    end


    def _to_nested_obj(aidx_, vec_, opts_)  # :nodoc:
      exclude_ = opts_.include?(:exclude_value)
      exclude_value_ = opts_[:exclude_value] if exclude_
      axis_ = @structure.get_axis(aidx_)
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
            sort_ = field_[:sort]
            if sort_
              if sort_.respond_to?(:call)
                func_ = sort_
              elsif sort_ == :numeric
                func_ = @numeric_sort
              else
                func_ = nil
              end
              labels_.sort!(&func_)
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
