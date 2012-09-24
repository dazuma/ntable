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


  # This is a "null" axis that has no elements.
  # Not terribly useful by itself, but may be a reasonable base class.
  # Accordingly, we will use this class to document the methods
  # required for an axis object.
  #
  # In general, an axis describes a particular dimension in the table:
  # how large the table is in that dimension, and how the ordered
  # "rows" along that dimension are named.

  class EmptyAxis


    # Axis objects must implement an equality check.

    def eql?(obj_)
      obj_.is_a?(EmptyAxis)
    end
    alias_method :==, :eql?


    # Axis objects must implement a hash

    def hash
      self.class.hash
    end


    # Axis methods should implement display methods for debugging.

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)}>"
    end
    alias_method :to_s, :inspect


    # Return the number of rows along this axis.
    # An empty axis will return 0.

    def size
      0
    end


    # Given a label object, return the corresponding 0-based integer index.
    # Returns nil if the label is not recognized.

    def index(label_)
      nil
    end


    # Given a 0-based integer index, return the corresponding label object.
    # Returns nil if the index is out of bounds (i.e. is less than 0 or
    # greater than or equal to size.)

    def label(index_)
      nil
    end


    # Populate the given hash with the configuration of this axis.
    # The hash will eventually be serialized via JSON.

    def to_json_object(json_obj_)
    end


    # Configure this axis given a hash configuration that came from
    # a JSON serialization.

    def from_json_object(json_obj_)
    end


  end


  # An axis in which the labels are explicitly provided as strings.

  class LabeledAxis


    # Create a LabeledAxis given an array of the label strings.
    # Symbols may also be provided, but will be converted to strings.

    def initialize(*labels_)
      labels_ = labels_.flatten
      @a = labels_.map{ |label_| label_.to_s }
      @h = {}
      @a.each_with_index{ |n_, i_| @h[n_] = i_ }
      @size = labels_.size
    end


    # See EmptyAxis#eql?
    def eql?(obj_)
      obj_.is_a?(LabeledAxis) && @a.eql?(obj_.instance_variable_get(:@a))
    end
    alias_method :==, :eql?

    # See EmptyAxis#hash
    def hash
      @a.hash
    end

    # See EmptyAxis#inspect
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} #{@a.inspect}>"
    end
    alias_method :to_s, :inspect


    # See EmptyAxis#size
    attr_reader :size


    # See EmptyAxis#index
    def index(label_)
      @h[label_.to_s]
    end

    # See EmptyAxis#label
    def label(index_)
      @a[index_]
    end


    # See EmptyAxis#to_json_object
    def to_json_object(json_obj_)
      json_obj_['labels'] = @a
    end

    # See EmptyAxis#from_json_object
    def from_json_object(json_obj_)
      initialize(json_obj_['labels'] || [])
    end


  end


  # An axis in which the rows are numerically identified by a range
  # of consecutive integers.

  class IndexedAxis


    # Create an IndexedAxis with the given number of rows. The optional
    # start parameter indicates the number of the first row (default 0).

    def initialize(size_, start_=0)
      @size = size_
      @start = start_
    end


    # See EmptyAxis#eql?
    def eql?(obj_)
      obj_.is_a?(IndexedAxis) && obj_.size.eql?(@size) && obj_.start.eql?(@start)
    end
    alias_method :==, :eql?

    # See EmptyAxis#hash
    def hash
      @size.hash ^ @start.hash
    end

    # See EmptyAxis#inspect
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} size=#{@size} start=#{@start}>"
    end
    alias_method :to_s, :inspect


    # See EmptyAxis#size
    attr_reader :size

    # Retrieve the number of the first row
    attr_reader :start


    # See EmptyAxis#index
    def index(label_)
      label_ >= @start && label_ < @size + @start ? label_ - @start : nil
    end

    # See EmptyAxis#label
    def label(index_)
      index_ >= 0 && index_ < @size ? index_ + @start : nil
    end


    # See EmptyAxis#to_json_object
    def to_json_object(json_obj_)
      json_obj_['size'] = @size
      json_obj_['start'] = @start unless @start == 0
    end

    # See EmptyAxis#from_json_object
    def from_json_object(json_obj_)
      initialize(json_obj_['size'], json_obj_['start'].to_i)
    end


  end


  # An axis in which the labels are arbitrary objects.
  # This axis cannot be serialized.

  class ObjectAxis


    # Create a ObjectAxis given an array of the label objects.

    def initialize(labels_)
      @a = labels_.dup
      @h = {}
      @a.each_with_index{ |n_, i_| @h[n_] = i_ }
      @size = labels_.size
    end


    # See EmptyAxis#eql?
    def eql?(obj_)
      obj_.is_a?(ObjectAxis) && @a.eql?(obj_.instance_variable_get(:@a))
    end

    # See EmptyAxis#==
    def ==(obj_)
      obj_.is_a?(ObjectAxis) && @a == obj_.instance_variable_get(:@a)
    end

    # See EmptyAxis#hash
    def hash
      @a.hash
    end

    # See EmptyAxis#inspect
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} #{@a.inspect}>"
    end
    alias_method :to_s, :inspect


    # See EmptyAxis#size
    attr_reader :size


    # See EmptyAxis#index
    def index(label_)
      @h[label_]
    end

    # See EmptyAxis#label
    def label(index_)
      @a[index_]
    end


    # See EmptyAxis#to_json_object
    def to_json_object(json_obj_)
      raise "Unable to JSON serialize an ObjectAxis"
    end

    # See EmptyAxis#from_json_object
    def from_json_object(json_obj_)
      raise "Unable to JSON serialize an ObjectAxis"
    end


  end


end
