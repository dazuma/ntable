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


  # Labeled axis

  class LabeledAxis


    def initialize(labels_)
      @a = labels_.dup
      @h = {}
      labels_.each_with_index{ |n_, i_| @h[n_] = i_ }
      @size = labels_.size
    end


    def eql?(obj_)
      obj_.is_a?(LabeledAxis) && obj_.instance_variable_get(:@a).eql?(@a)
    end
    alias_method :==, :eql?

    def hash
      @a.hash
    end


    attr_reader :size

    def label_to_index(label_)
      @h[label_]
    end

    def index_to_label(index_)
      @a[index_]
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
      @size + @start
    end


    attr_reader :size
    attr_reader :start

    def label_to_index(label_)
      label_ >= @start && label_ < @size + @start ? label_ - @start : nil
    end

    def index_to_label(index_)
      index_ >= 0 && index_ < @size ? index_ + @start : nil
    end


  end


end
