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


module NTable


  # Structure object

  class Table


    def initialize(structure_, data_={})
      @structure = structure_
      @structure.lock!
      size_ = @structure.size
      load_ = data_[:load]
      fill_ = data_[:fill]
      if load_
        load_size_ = load_.size
        if load_size_ > size_
          @vals = load_[0, size_]
        elsif load_size_ < size_
          @vals = load_ + ::Array.new(size_ - load_size_, fill_)
        else
          @vals = load_.dup
        end
      else
        @vals = ::Array.new(size_, fill_)
      end
    end


    def initialize_copy(other_)
      initialize(@structure, :load => @vals)
    end


    def eql?(obj_)
      obj_.is_a?(Table) && obj_.structure.eql?(@structure) &&
        obj_.instance_variable_get(:@vals).eql?(@vals)
    end
    alias_method :==, :eql?


    attr_reader :structure


    def size
      @vals.size
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


    def get(*args_)
      if args_.size == 1
        first_ = args_.first
        args_ = first_ if first_.is_a?(::Hash) || first_.is_a?(::Array)
      end
      offset_ = @structure.offset(args_)
      offset_ ? @vals[offset_] : nil
    end
    alias_method :[], :get


    def set!(*args_, &block_)
      value_ = block_ ? nil : args_.pop
      if args_.size == 1
        first_ = args_.first
        args_ = first_ if first_.is_a?(::Hash) || first_.is_a?(::Array)
      end
      offset_ = @structure.offset(args_)
      if offset_
        value_ = block_.call(@vals[offset_]) if block_
        @vals[offset_] = value_
      else
        nil
      end
    end
    alias_method :[]=, :set!


    def load!(vals_)
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
      @vals.fill(value_)
    end


    def slice(hash_)
      offset_ = 0
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

      outer_ainfo_ = (0...@structure.dim).find_all{ |i_| !select_set_.include?(i_) }.
        map{ |i_| @structure.axis_info(i_) }
      slice_struct_ = Structure.new
      outer_ainfo_.each{ |ainfo_| slice_struct_.add(ainfo_.axis, ainfo_.name) }

      if @structure.empty?
        Table.new(slice_struct_)
      else
        outer_vector_ = ::Array.new(outer_ainfo_.size, 0)
        outer_index_ = 0
        result_vals_ = ::Array.new(outer_ainfo_.inject(1){ |p_, ai_| p_ * ai_.axis.size }) do
          val_ = @vals[outer_index_ + offset_]
          (outer_vector_.size - 1).downto(0) do |i_|
            step_ = outer_ainfo_[i_].step
            outer_index_ += step_
            v_ = outer_vector_[i_] += 1
            break if v_ < outer_ainfo_[i_].axis.size
            outer_index_ -= v_ * step_
            outer_vector_[i_] = 0
          end
          val_
        end
        Table.new(slice_struct_, :load => result_vals_)
      end
    end


  end


end
