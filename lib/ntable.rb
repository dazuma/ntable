# -----------------------------------------------------------------------------
#
# NTable main file
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


# NTable is an N-dimensional table data structure for Ruby.
#
# == Basics
#
# This is a convenient data structure for storing tabular data of
# arbitrary dimensionality. An NTable can represent zero-dimensional data
# (i.e. a simple scalar value), one-dimensional data (i.e. an array or
# dictionary), a two-dimensional table such as a database result set or
# spreadsheet, or any number of higher dimensions.
#
# The structure of the table is defined explicitly. Each dimension is
# represented by an axis, which describes how many "rows" the table has
# in that dimension, and how each row is labeled. For example, you could
# have a "numeric" indexed axis whose rows are identified by indexes.
# Or you could have a "string" labeled axis identified by names (e.g.
# columns in a database.)
#
# For example, a typical two-dimensional spreadsheet would have
# numerically-identified "rows", and columns identified by name. You might
# describe the structure of the table with two axes, the major one a
# numeric indexed axis, and the minor one a string labeled axis. In code,
# such a table with 100 rows and two columns could be created like this:
#
#  table = NTable.structure(NTable::IndexedAxis.new(100)).
#                 add(NTable::LabeledAxis.new(:name, :address)).
#                 create
#
# You can then look up individual cells like this:
#
#  value = table[10, :address]
#
# Axes can be given names as well:
#
#  table = NTable.structure(NTable::IndexedAxis.new(100), :row).
#                 add(NTable::LabeledAxis.new(:name, :address), :col).
#                 create
#
# Then you can specify the axes by name when you look up:
#
#  value = table[:row => 10, :col => :address]
#
# You can use the same syntax to set data:
#
#  table[10, :address] = "123 Main Street"
#  table[:row => 10, :col => :address] = "123 Main Street"
#
# == Iterating
#
# (to be written)
#
# == Slicing and decomposition
#
# (to be written)
#
# == Serialization
#
# (to be written)

module NTable
end


require 'ntable/errors'
require 'ntable/axis'
require 'ntable/structure'
require 'ntable/index_wrapper'
require 'ntable/table'
require 'ntable/construction'
