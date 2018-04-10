//
//  FloatingGeneral.metal
//  C3
//
//  Created by Kota Nakano on 4/9/18.
//

#include <metal_stdlib>
using namespace metal;
constant uint const count [[ function_constant(0) ]];
template<typename T> T const square(T const x) {
	return x * x;
}
template<typename T> T erf(T const z) {
	T const v = 1.0 / fma(fabs(z), T(0.5), 1);
	T const w[] = {
		0.17087277,
		-0.82215223,
		1.48851587,
		-1.13520398,
		0.27886807,
		-0.18628806,
		0.09678418,
		0.37409196,
		1.00002368,
		1.26551223
	};
	return copysign(fma(-v,
						exp(
							fma(v,
								fma(v,
									fma(v,
										fma(v,
											fma(v,
												fma(v,
													fma(v,
														fma(v,
															fma(v,
																w[0],
																w[1]),
															w[2]),
														w[3]),
													w[4]),
												w[5]),
											w[6]),
										w[7]),
									w[8]),
								- fma(z, z, w[9]))),
						1),
					z);
}
//refer: Mike Giles, ``Approximating the erfinv function, ''
template<typename T> T erfinv(T const x) {
	T const f[] = {
		2.81022636e-08,
		3.43273939e-07,
		-3.5233877e-06,
		-4.39150654e-06,
		0.00021858087,
		-0.00125372503,
		-0.00417768164,
		0.246640727,
		1.50140941};
	T const g[] = {
		-0.000200214257,
		0.000100950558,
		0.00134934322,
		-0.00367342844,
		0.00573950773,
		-0.0076224613,
		0.00943887047,
		1.00167406,
		2.83297682
	};
	T const z = - log ( - fma ( x, x, -1 ) );
	bool const s = z < 5.0;
	auto const r = s ? f : g;
	T const w = select(sqrt(z) - 3.0, z - 2.5, s);
	return fma(w,
			   fma(w,
				   fma(w,
					   fma(w,
						   fma(w,
							   fma(w,
								   fma(w,
									   fma(w, r[0],
										   r[1]),
									   r[2]),
								   r[3]),
							   r[4]),
						   r[5]),
					   r[6]),
				   r[7]),
			   r[8]) * x;
}
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

