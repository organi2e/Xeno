//
//  FMA.metal
//  C3
//
//  Created by Kota Nakano on 4/10/18.
//

#include <metal_stdlib>
using namespace metal;
constant uint const count [[ function_constant(0) ]];

constant half const a_half [[ function_constant(1) ]];
constant half const b_half [[ function_constant(2) ]];

constant float const a_float [[ function_constant(3) ]];
constant float const b_float [[ function_constant(4) ]];

#define FMAVSS(T) kernel void FMAVSS_ ## T (\
	device T * const y [[ buffer(0) ]],\
	device T const * const x [[ buffer(1) ]],\
	uint const index [[ thread_position_in_grid ]]) {\
	if ( index < count ) y [ index ] = fma ( x [ index ], a_ ## T, b_ ## T );\
}
FMAVSS(half)
FMAVSS(float)

#define FMAVSV(T) kernel void FMAVSV_ ## T (\
	device T * const y [[ buffer(0) ]],\
	device T const * const x [[ buffer(1) ]],\
	device T const * const b [[ buffer(2) ]],\
	uint const index [[ thread_position_in_grid ]]) {\
	if ( index < count ) y [ index ] = fma ( x [ index ], a_ ## T, b [ index ] );\
}
FMAVSV(half)
FMAVSV(float)

#define FMAVVS(T) kernel void FMAVVS_ ## T (\
	device T * const y [[ buffer(0) ]],\
	device T const * const x [[ buffer(1) ]],\
	device T const * const a [[ buffer(2) ]],\
	uint const index [[ thread_position_in_grid ]]) {\
	if ( index < count ) y [ index ] = fma ( x [ index ], a [ index ], b_ ## T );\
}
FMAVVS(half)
FMAVVS(float)

#define FMAVVV(T) kernel void FMAVVV_ ## T (\
	device T * const y [[ buffer(0) ]],\
	device T const * const x [[ buffer(1) ]],\
	device T const * const a [[ buffer(2) ]],\
	device T const * const b [[ buffer(3) ]],\
	uint const index [[ thread_position_in_grid ]]) {\
	if ( index < count ) y [ index ] = fma ( x [ index ], a [ index ], b [ index ] );\
}
FMAVVV(half)
FMAVVV(float)
