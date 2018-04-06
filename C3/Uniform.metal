//
//  Uniform.metal
//  C3
//
//  Created by Kota Nakano on 4/6/18.
//

#include <metal_stdlib>
using namespace metal;
constant uint const count [[ function_constant(0) ]];
kernel void normalize_half_uchar(device half * const y [[ buffer(0) ]],
								 device uchar const * const x [[ buffer(1) ]],
								 uint const index [[ thread_position_in_grid ]]) {
	if ( index < count ) y [ index ] = x [ index ] / 256.0;
}
kernel void normalize_float_ushort(device float * const y [[ buffer(0) ]],
								   device ushort const * const x [[ buffer(1) ]],
								   uint const index [[ thread_position_in_grid ]]) {
	if ( index < count ) y [ index ] = x [ index ] / 65536.0;
}

