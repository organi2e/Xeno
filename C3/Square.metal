//
//  Square.metal
//  C3
//
//  Created by Kota Nakano on 4/3/18.
//

#include <metal_stdlib>
using namespace metal;
constant uint N [[ function_constant(0) ]];
template<typename T> T const square(T const x) {
	return x * x;
}
kernel void square_s8(device char * const y [[ buffer(0) ]],
					  device char const * const x [[ buffer(1) ]],
					  uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_u8(device uchar * const y [[ buffer(0) ]],
					  device uchar const * const x [[ buffer(1) ]],
					  uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_s16(device short * const y [[ buffer(0) ]],
					   device short const * const x [[ buffer(1) ]],
					   uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_u16(device ushort * const y [[ buffer(0) ]],
					   device ushort const * const x [[ buffer(1) ]],
					   uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_s32(device int * const y [[ buffer(0) ]],
					   device int const * const x [[ buffer(1) ]],
					   uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_u32(device uint * const y [[ buffer(0) ]],
					   device uint const * const x [[ buffer(1) ]],
					   uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_f16(device half * const y [[ buffer(0) ]],
					   device half const * const x [[ buffer(1) ]],
					   uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_f32(device float * const y [[ buffer(0) ]],
					   device float const * const x [[ buffer(1) ]],
					   uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}

