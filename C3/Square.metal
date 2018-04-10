//
//  Square.metal
//  C3
//
//  Created by Kota Nakano on 4/3/18.
//

#include <metal_stdlib>
using namespace metal;
constant uint count [[ function_constant(0) ]];
template<typename T> T const square(T const x) {
	return x * x;
}
#define SQUARE(T) kernel void square_ ## T (\
	device T * const y [[ buffer(0) ]],\
	device T const * const x [[ buffer(1) ]],\
	uint const index [[ thread_position_in_grid ]]) {\
	if ( index < count ) y [ index ] = square ( x [ index ] );\
}
SQUARE(char)
SQUARE(short)
SQUARE(int)

SQUARE(uchar)
SQUARE(ushort)
SQUARE(uint)

SQUARE(half)
SQUARE(float)
