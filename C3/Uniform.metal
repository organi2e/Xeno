//
//  Uniform.metal
//  C3
//
//  Created by Kota Nakano on 4/6/18.
//

#include <metal_stdlib>
using namespace metal;
constant uint const count [[ function_constant(0) ]];
#define NORMALIZE(D, S, scale) kernel void normalize ## _ ## D ## _ ## S (\
	device D * const y [[ buffer(0) ]],\
	device S const * const x [[ buffer(1) ]],\
	uint const index [[ thread_position_in_grid ]]) {\
	if ( index < count ) y [ index ] = ( D ( x [ index ] ) + 0.5 ) / D ( scale ); \
}
NORMALIZE(half, uchar, 256)
NORMALIZE(float, uchar, 256)
NORMALIZE(float, ushort, 65536)
