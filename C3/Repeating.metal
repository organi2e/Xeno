//
//  Repeating.metal
//  C3
//
//  Created by Kota Nakano on 4/11/18.
//
#include <metal_stdlib>
using namespace metal;
constant uint const target_rows [[ function_constant(0) ]];
constant uint const source_rows [[ function_constant(2) ]];
constant uint const target_columns [[ function_constant(1) ]];
constant uint const source_columns [[ function_constant(3) ]];
#define REPEATING(T) kernel void repeating_ ## T (\
	device T * const y [[ buffer(0) ]],\
	device T const * const x [[ buffer(1) ]],\
	uint const index [[ thread_position_in_grid ]]) {\
	uint const tr = index / target_columns;\
	uint const tc = index % target_columns;\
	if ( tr < target_rows && tc < target_columns ) {\
		uint const sr = tr % source_rows;\
		uint const sc = tc % source_columns;\
		y [ index ] = x [ sr * source_columns + sc ];\
	}\
}
REPEATING(char)
REPEATING(short)
REPEATING(int)

REPEATING(uchar)
REPEATING(ushort)
REPEATING(uint)

REPEATING(half)
REPEATING(float)
