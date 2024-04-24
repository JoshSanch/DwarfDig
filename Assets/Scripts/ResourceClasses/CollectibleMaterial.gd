class_name CollectableMaterial
extends Resource

@export var randomize_rotation := false
@export var max_spawn_rate := 0.1
@export var spawn_limits: Curve


func get_spawn_chance(depth: float, max_depth: float) -> float:
	return spawn_limits.sample(depth / max_depth) * max_spawn_rate


func can_spawn(depth: float, max_depth: float) -> bool:
	return randf() < get_spawn_chance(depth, max_depth)


# https://gitlab.com/20-games-in-30-days/motherload/-/tree/main
# MIT License

# Copyright (c) 2022 20-in-30

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# -- SdgGames <sdggamecollective.org>
