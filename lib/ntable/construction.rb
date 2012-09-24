# -----------------------------------------------------------------------------
#
# NTable constructors
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


require 'set'
require 'json'


module NTable


  @numeric_sort = ->(a_, b_){ a_.to_f <=> b_.to_f }
  @integer_sort = ->(a_, b_){ a_.to_i <=> b_.to_i }
  @string_sort = ->(a_, b_){ a_.to_s <=> b_.to_s }


  class << self


    # Create and return a new Structure.
    #
    # If you pass the optional axis argument, that axis will be added
    # to the structure.
    #
    # The most convenient way to create a table is probably to chain
    # methods off this method. For example:
    #
    #  NTable.structure(NTable::IndexedAxis.new(10)).
    #    add(NTable::LabeledAxis.new(:column1, :column2)).
    #    create(:fill => 0)

    def structure(axis_=nil, name_=nil)
      axis_ ? Structure.add(axis_, name_) : Structure.new
    end


    # Create a table with the given Structure.
    #
    # You can initialize the data using the following options:
    #
    # [<tt>:fill</tt>]
    #   Fill all cells with the given value.
    # [<tt>:load</tt>]
    #   Load the cell data with the values from the given array, in order.

    def create(structure_, data_={})
      Table.new(structure_, data_)
    end


    # Construct a table given a JSON object representation.

    def from_json_object(json_)
      Table.new(Structure.from_json_array(json_['axes'] || []), :load => json_['values'] || [])
    end


    # Construct a table given a JSON unparsed string representation.

    def parse_json(json_)
      from_json_object(::JSON.parse(json_))
    end


    # Construct a table given nested hashes and arrays.
    #
    # The second argument is an array of hashes, providing options for
    # the axes in order. Recognized keys in these hashes include:
    #
    # [<tt>:name</tt>]
    #   The name of the axis, as a string or symbol
    # [<tt>:sort</tt>]
    #   The sort strategy. You can provide a callable object such as a
    #   Proc, or one of the constants <tt>:numeric</tt> or
    #   <tt>:string</tt>. If you omit this key or set it to false, no
    #   sort is done on the labels for this axis.
    # [<tt>:objectify</tt>]
    #   An optional Proc that modifies the labels. The Proc should take
    #   a single argument and return the new label. If an objectify
    #   proc is provided, the resulting axis will be an ObjectAxis.
    #   You can also pass true instead of a Proc; this will create an
    #   ObjectAxis and make the conversion a nop.
    # [<tt>:stringify</tt>]
    #   An optional Proc that modifies the labels. The Proc should take
    #   a single argument and return the new label, which will then be
    #   converted to a string if it isn't one already. If a stringify
    #   proc is provided, the resulting axis will be a LabeledAxis.
    #   You can also pass true instead of a Proc; this will create an
    #   LabeledAxis and make the conversion a simple to_s.
    # [<tt>:postprocess</tt>]
    #   An optional Proc that postprocesses the final labels array.
    #   It should take an array of labels and return a modified array
    #   (which can be the original array modified in place). Called
    #   after any sort has been completed.
    #   You can use this, for example, to "fill in" labels that were
    #   not present in the original data.
    #
    # The third argument is an optional hash of miscellaneous options.
    # The following keys are recognized:
    #
    # [<tt>:fill</tt>]
    #   Fill all cells not explicitly set, with the given value.
    #   Default is nil.
    # [<tt>:objectify_by_default</tt>]
    #   By default, all hash-created axes are LabeledAxis unless an
    #   <tt>:objectify</tt> field option is explicitly provided. This
    #   option, if true, reverses this behavior. You can pass true, or
    #   a Proc that transforms the label.
    # [<tt>:stringify_by_default</tt>]
    #   If set to a Proc, this Proc is used as the default stringification
    #   routine for converting labels for a LabeledAxis.

    def from_nested_object(obj_, field_opts_=[], opts_={})
      axis_data_ = []
      _populate_nested_axes(axis_data_, 0, obj_)
      objectify_by_default_ = opts_[:objectify_by_default]
      stringify_by_default_ = opts_[:stringify_by_default]
      struct_ = Structure.new
      axis_data_.each_with_index do |ai_, i_|
        field_ = field_opts_[i_] || {}
        axis_ = nil
        name_ = field_[:name]
        case ai_
        when ::Hash
          objectify_ = field_[:objectify]
          stringify_ = field_[:stringify] || stringify_by_default_
          objectify_ ||= objectify_by_default_ unless stringify_
          if objectify_
            if objectify_.respond_to?(:call)
              h_ = ::Set.new
              ai_.keys.each do |k_|
                nv_ = objectify_.call(k_)
                ai_[k_] = nv_
                h_ << nv_
              end
              labels_ = h_.to_a
            else
              labels_ = ai_.keys
            end
            klass_ = ObjectAxis
          else
            stringify_ = nil unless stringify_.respond_to?(:call)
              h_ = ::Set.new
            ai_.keys.each do |k_|
              nv_ = (stringify_ ? stringify_.call(k_) : k_).to_s
              ai_[k_] = nv_
              h_ << nv_
            end
            labels_ = h_.to_a
            klass_ = LabeledAxis
          end
          if (sort_ = field_[:sort])
            if sort_.respond_to?(:call)
              func_ = sort_
            elsif sort_ == :string
              func_ = @string_sort
            elsif sort_ == :integer
              func_ = @integer_sort
            elsif sort_ == :numeric
              func_ = @numeric_sort
            else
              func_ = nil
            end
            labels_.sort!(&func_)
          end
          postprocess_ = field_[:postprocess]
          labels_ = postprocess_.call(labels_) if postprocess_.respond_to?(:call)
          axis_ = klass_.new(labels_)
        when ::Array
          axis_ = IndexedAxis.new(ai_[1].to_i - ai_[0].to_i, ai_[0].to_i)
        end
        struct_.add(axis_, name_) if axis_
      end
      table_ = Table.new(struct_, :fill => opts_[:fill])
      _populate_nested_values(table_, [], axis_data_, obj_)
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
          (ai_[0]...ai_[1]).each{ |i_| set_[i_] = i_ } if ::Array === ai_
        end
        obj_.each do |k_, v_|
          set_[k_] = k_
          _populate_nested_axes(axis_data_, index_+1, v_)
        end
      when ::Array
        if ::Hash === ai_
          obj_.each_with_index do |v_, i_|
            ai_[i_] = i_
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


    def _populate_nested_values(table_, path_, axis_data_, obj_)  # :nodoc:
      if path_.size == table_.dim
        table_.set!(*path_, obj_)
      else
        case obj_
        when ::Hash
          h_ = axis_data_[path_.size]
          obj_.each do |k_, v_|
            _populate_nested_values(table_, path_ + [h_[k_]], axis_data_, v_)
          end
        when ::Array
          obj_.each_with_index do |v_, i_|
            _populate_nested_values(table_, path_ + [i_], axis_data_, v_) unless v_.nil?
          end
        end
      end
    end


  end


  class Table

    class << self


      # Deprecated synonym for ::NTable.from_json_object

      def from_json_object(json_)
        ::NTable.from_json_object(json_)
      end


      # Deprecated synonym for ::NTable.parse_json

      def parse_json(json_)
        ::NTable.parse_json(json_)
      end


      # Deprecated synonym for ::NTable.from_nested_object

      def from_nested_object(obj_, field_opts_=[], opts_={})
        ::NTable.from_nested_object(obj_, field_opts_, opts_)
      end


    end

  end


end
