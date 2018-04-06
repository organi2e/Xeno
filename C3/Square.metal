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
kernel void square_char(device char * const y [[ buffer(0) ]],
						device char const * const x [[ buffer(1) ]],
						uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_uchar(device uchar * const y [[ buffer(0) ]],
						 device uchar const * const x [[ buffer(1) ]],
						 uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_short(device short * const y [[ buffer(0) ]],
						 device short const * const x [[ buffer(1) ]],
						 uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_ushort(device ushort * const y [[ buffer(0) ]],
						  device ushort const * const x [[ buffer(1) ]],
						  uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_int(device int * const y [[ buffer(0) ]],
					   device int const * const x [[ buffer(1) ]],
					   uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_uint(device uint * const y [[ buffer(0) ]],
						device uint const * const x [[ buffer(1) ]],
						uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_half(device half * const y [[ buffer(0) ]],
						device half const * const x [[ buffer(1) ]],
						uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}
kernel void square_float(device float * const y [[ buffer(0) ]],
						 device float const * const x [[ buffer(1) ]],
						 uint const n [[ thread_position_in_grid ]]) {
	if ( n < N ) y [ n ] = square ( x [ n ] );
}

