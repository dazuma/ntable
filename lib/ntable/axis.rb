# -----------------------------------------------------------------------------
#
# NTable axis objects
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


  class EmptyAxis


    def size
      0
    end


    def label_to_index(label_)
      nil
    end


    def index_to_label(index_)
      nil
    end


    def concat(rhs_)
      rhs_
    end


    def to_json_object(json_obj_)
    end


    def from_json_object(json_obj_)
    end


  end


  # Labeled axis

  class LabeledAxis


    def initialize(labels_)
      @a = labels_.map{ |label_| label_.to_s }
      @h = {}
      @a.each_with_index{ |n_, i_| @h[n_] = i_ }
      @size = labels_.size
    end


    def eql?(obj_)
      obj_.is_a?(LabeledAxis) && obj_.instance_variable_get(:@a).eql?(@a)
    end
    alias_method :==, :eql?

    def hash
      @a.hash
    end

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} #{@a.inspect}>"
    end
    alias_method :to_s, :inspect


    attr_reader :size

    def label_to_index(label_)
      @h[label_.to_s]
    end

    def index_to_label(index_)
      @a[index_]
    end


    def concat(rhs_)
      if rhs_.is_a?(LabeledAxis) && !@a.find{ |label_| rhs_.label_to_index(label_) }
        LabeledAxis.new(@a + rhs_.instance_variable_get(:@a))
      else
        nil
      end
    end


    def to_json_object(json_obj_)
      json_obj_['labels'] = @a
    end


    def from_json_object(json_obj_)
      initialize(json_obj_['labels'] || [])
    end


  end


  # Indexed axis

  class IndexedAxis


    def initialize(size_, start_=0)
      @size = size_
      @start = start_
    end


    def eql?(obj_)
      obj_.is_a?(IndexedAxis) && obj_.size.eql?(@size) && obj_.start.eql?(@start)
    end
    alias_method :==, :eql?

    def hash
      @size.hash + @start.hash
    end

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} size=#{@size} start=#{@start}>"
    end
    alias_method :to_s, :inspect


    attr_reader :size
    attr_reader :start

    def label_to_index(label_)
      label_ >= @start && label_ < @size + @start ? label_ - @start : nil
    end

    def index_to_label(index_)
      index_ >= 0 && index_ < @size ? index_ + @start : nil
    end


    def concat(rhs_)
      if rhs_.is_a?(IndexedAxis)
        IndexedAxis.new(@size + rhs_.size, @start)
      else
        nil
      end
    end


    def to_json_object(json_obj_)
      json_obj_['size'] = @size
      json_obj_['start'] = @start unless @start == 0
    end


    def from_json_object(json_obj_)
      initialize(json_obj_['size'], json_obj_['start'].to_i)
    end


  end


end
