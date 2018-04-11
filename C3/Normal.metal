//
//  Normal.metal
//  C3
//
//  Created by Kota Nakano on 3/30/18.
//

#include <metal_stdlib>
#include "Approx.h"
using namespace metal;
constant uint const count [[ function_constant(0) ]];

constant float a_float_short = 1 / 32768.0;
constant float b_float_short = 1 / 65536.0;
constant float r_float = M_SQRT2_F;

constant half a_half_char = 1 / 128.0;
constant half b_half_char = 1 / 256.0;
constant half r_half = M_SQRT2_H;

#define RNG(F, U) kernel void normal_rng_ ## F ##_ ## U (\
	device F * const y [[ buffer(0) ]],\
	device U const * const u [[ buffer(1) ]],\
	uint const index [[ thread_position_in_grid ]]) {\
	if ( index < count ) y [ index ] = r_ ## F * erfinv ( fma ( u [ index ], a_ ## F ## _ ## U, b_ ## F ## _ ## U ));\
}

RNG(half, char)
RNG(float, short)
