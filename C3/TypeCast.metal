//
//  TypeCast.metal
//  C3
//
//  Created by Kota Nakano on 4/3/18.
//
#include <metal_stdlib>
using namespace metal;
kernel void typecast(device float * x [[ buffer(0) ]],
					 device half * y [[ buffer(1) ]]) {
	x[0] = y[0];
}
