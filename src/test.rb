# frozen_string_literal: true

require 'phashion'

p1 = 11_295_476_454_014_558_235
p2 = 11_367_533_435_196_510_746

p Phashion.hamming_distance(p1, p2)
