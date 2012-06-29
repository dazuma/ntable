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


    def initialize
      @indexes = []
      @names = {}
      @size = nil
      @steps = nil
    end


    def initialize_copy(other_)
      initialize
      other_.instance_variable_get(:@indexes).each{ |ai_| add(ai_.first, ai_.last) }
      if other_.locked?
        @size = other_.size
        @steps = other_.instance_variable_get(:@steps)
      end
    end


    def unlocked_copy
      copy_ = Structure.new
      @indexes.each{ |ai_| copy_.add(ai_.first, ai_.last) }
      copy_
    end


    def add(axis_, name_=nil)
      raise "Structure locked" if @size
      name_ = name_ ? name_.to_s : nil
      index_ = @indexes.size
      ainfo_ = [axis_, index_, name_]
      @indexes << ainfo_
      @names[name_] = ainfo_ if name_
      self
    end


    def remove(axis_)
      raise "Structure locked" if @size
      if (ainfo_ = _axis_info(axis_))
        index_ = ainfo_[1]
        @names.delete(ainfo_[2])
        @indexes.delete_at(index_)
        @indexes[index_..-1].each{ |ai_| ai_[1] -= 1 }
      end
      self
    end


    def replace(axis_, naxis_=nil)
      raise "Structure locked" if @size
      if (ainfo_ = _axis_info(axis_))
        naxis_ ||= yield(ainfo_[0], ainfo_[1], ainfo_[2])
        ainfo_[0] = naxis_
      end
      self
    end


    def dim
      @indexes.size
    end


    def get_axis(spec_)
      ainfo_ = _axis_info(spec_)
      ainfo_ ? ainfo_.first : nil
    end


    def get_name(spec_)
      ainfo_ = _axis_info(spec_)
      ainfo_ ? ainfo_[2] : nil
    end


    def get_index(spec_)
      ainfo_ = _axis_info(spec_)
      ainfo_ ? ainfo_[1] : nil
    end


    def lock!
      unless @size
        if @indexes.size > 0
          @size = @indexes.inject(1){ |size_, ainfo_| size_ * ainfo_.first.size }
        else
          @size = 0
        end
        if @size == 0
          @steps = nil
        else
          s_ = @size
          @steps = @indexes.map{ |ainfo_| s_ /= ainfo_.first.size }
        end
      end
      self
    end


    def locked?
      @size ? true : false
    end


    def size
      raise "Structure not locked" unless @size
      @size
    end


    def empty?
      raise "Structure not locked" unless @size
      @steps.nil?
    end


    def offset(args_)
      return nil unless @steps
      case args_
      when ::Hash
        offset_ = 0
        args_.each do |k_, v_|
          if (ainfo_ = _axis_info(k_))
            index_ = ainfo_.first.label_to_index(v_)
            return nil unless index_
            offset_ += @steps[ainfo_[1]] * index_
          else
            return nil
          end
        end
        offset_
      when ::Array
        offset_ = 0
        args_.each_with_index do |v_, i_|
          if (ainfo_ = @indexes[i_])
            index_ = ainfo_.first.label_to_index(v_)
            return nil unless index_
            offset_ += @steps[ainfo_[1]] * index_
          else
            return nil
          end
        end
        offset_
      else
        nil
      end
    end


    def _axis_info(axis_)
      case axis_
      when ::Integer
        @indexes[axis_]
      else
        @names[axis_.to_s]
      end
    end


  end


end
