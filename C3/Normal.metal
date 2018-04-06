//
//  Normal.metal
//  C3
//
//  Created by Kota Nakano on 3/30/18.
//

#include <metal_stdlib>
using namespace metal;
template<typename T> T erfinv(T const x) {
	T const w = log( - fma (x, x, -1) );
	T p;
	if ( w < 5.000000f ) {
		w = w - 2.500000f;
		p= 2.81022636e-08f;
		p= 3.43273939e-07f + p * w;
		p= -3.5233877e-06f + p * w;
		p = -4.39150654e-06f + p * w;
		p = 0.00021858087f + p * w;
		p = -0.00125372503f + p * w;
		p = -0.00417768164f + p * w;
		p = 0.246640727f + p * w;
		p = 1.50140941f + p * w;
	} else {
		w = sqrt(w) - 3.000000f;
		p = -0.000200214257f;
		p = 0.000100950558f + p * w;
		p = 0.00134934322f + p * w;
		p = -0.00367342844f + p * w;
		p = 0.00573950773f + p * w;
		p = -0.0076224613f + p * w;
		p = 0.00943887047f + p * w;
		p = 1.00167406f + p * w;
		p = 2.83297682f + p * w;
	}
	return p * x;
}
