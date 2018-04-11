//
//  FloatingGeneral.metal
//  C3
//
//  Created by Kota Nakano on 4/9/18.
//

#include <metal_stdlib>
#include "Approx.h"
using namespace metal;
constant uint const count [[ function_constant(0) ]];
#define F1(f, T) kernel void f ## _ ## T(\
	device T * const y [[ buffer(0) ]], \
	device T const * const x [[ buffer(1) ]], \
	uint const index [[ thread_position_in_grid ]] ) {\
	if ( index < count ) y [ index ] = f ( x [ index ] );\
}
#define F2(f, T) kernel void f ## _ ## T(\
	device T * const y [[ buffer(0) ]], \
	device T const * const x0 [[ buffer(1) ]], \
	device T const * const x1 [[ buffer(2) ]], \
	uint const index [[ thread_position_in_grid ]] ) {\
	if ( index < count ) y [ index ] = f ( x0 [ index ], x1 [ index ] );\
}
#define F3(f, T) kernel void f ## _ ## T(\
	device T * const y [[ buffer(0) ]], \
	device T const * const x0 [[ buffer(1) ]], \
	device T const * const x1 [[ buffer(2) ]], \
	device T const * const x2 [[ buffer(3) ]], \
	uint const index [[ thread_position_in_grid ]] ) {\
	if ( index < count ) y [ index ] = f ( x0 [ index ], x1 [ index ], x2 [ index ] );\
}
#define F4(f, T) kernel void f ## _ ## T(\
	device T * const y [[ buffer(0) ]], \
	device T const * const x0 [[ buffer(1) ]], \
	device T const * const x1 [[ buffer(2) ]], \
	device T const * const x2 [[ buffer(3) ]], \
	device T const * const x3 [[ buffer(4) ]], \
	uint const index [[ thread_position_in_grid ]] ) {\
	if ( index < count ) y [ index ] = f ( x0 [ index ], x1 [ index ], x2 [ index ], x3 [ index ] );\
}

F1(acos, half)
F1(acosh, half)
F1(asin, half)
F1(asinh, half)
F1(atan, half)
F2(atan2, half)
F1(atanh, half)
F1(ceil, half)
F2(copysign, half)
F1(cos, half)
F1(cosh, half)
F1(cospi, half)
F1(exp, half)
F1(exp2, half)
F1(exp10, half)
F1(fabs, half)
F1(abs, half)
F2(fdim, half)
F1(floor, half)
F3(fma, half)
F2(fmax, half)
F2(max, half)
F2(fmin, half)
F2(min, half)
F2(fmod, half)
F1(fract, half)
F1(log, half)
F1(log2, half)
F1(log10, half)
F2(pow, half)
F2(powr, half)
F1(rint, half)
F1(round, half)
F1(rsqrt, half)
F1(sin, half)
F1(sinh, half)
F1(sinpi, half)
F1(sqrt, half)
F1(tan, half)
F1(tanh, half)
F1(tanpi, half)
F1(trunc, half)
F1(erf, half)
F1(erfinv, half)
F3(clamp, half)

F1(acos, float)
F1(acosh, float)
F1(asin, float)
F1(asinh, float)
F1(atan, float)
F2(atan2, float)
F1(atanh, float)
F1(ceil, float)
F2(copysign, float)
F1(cos, float)
F1(cosh, float)
F1(cospi, float)
F1(exp, float)
F1(exp2, float)
F1(exp10, float)
F1(fabs, float)
F1(abs, float)
F2(fdim, float)
F1(floor, float)
F3(fma, float)
F2(fmax, float)
F2(max, float)
F2(fmin, float)
F2(min, float)
F2(fmod, float)
F1(fract, float)
F1(log, float)
F1(log2, float)
F1(log10, float)
F2(pow, float)
F2(powr, float)
F1(rint, float)
F1(round, float)
F1(rsqrt, float)
F1(sin, float)
F1(sinh, float)
F1(sinpi, float)
F1(sqrt, float)
F1(tan, float)
F1(tanh, float)
F1(tanpi, float)
F1(trunc, float)
F1(erf, float)
F1(erfinv, float)
F3(clamp, float)

