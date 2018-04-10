//
//  TypeCast.metal
//  C3
//
//  Created by Kota Nakano on 4/3/18.
//
#include <metal_stdlib>
using namespace metal;
constant uint const count [[ function_constant(0) ]];
#define TYPECAST(D, S) kernel void typecast_ ## D ##_ ## S (\
	device D * const y [[ buffer(0) ]],\
	device S const * const x [[ buffer(1) ]],\
	uint const index [[ thread_position_in_grid ]]) {\
	if ( index < count ) y [ index ] = x [ index ];\
}
TYPECAST(char, short)
TYPECAST(char, int)
TYPECAST(char, uchar)
TYPECAST(char, ushort)
TYPECAST(char, uint)
TYPECAST(char, half)
TYPECAST(char, float)

TYPECAST(short, char)
TYPECAST(short, int)
TYPECAST(short, uchar)
TYPECAST(short, ushort)
TYPECAST(short, uint)
TYPECAST(short, half)
TYPECAST(short, float)

TYPECAST(int, char)
TYPECAST(int, short)
TYPECAST(int, uchar)
TYPECAST(int, ushort)
TYPECAST(int, uint)
TYPECAST(int, half)
TYPECAST(int, float)

TYPECAST(uchar, char)
TYPECAST(uchar, short)
TYPECAST(uchar, int)
TYPECAST(uchar, ushort)
TYPECAST(uchar, uint)
TYPECAST(uchar, half)
TYPECAST(uchar, float)

TYPECAST(ushort, char)
TYPECAST(ushort, short)
TYPECAST(ushort, int)
TYPECAST(ushort, uchar)
TYPECAST(ushort, uint)
TYPECAST(ushort, half)
TYPECAST(ushort, float)

TYPECAST(uint, char)
TYPECAST(uint, short)
TYPECAST(uint, int)
TYPECAST(uint, uchar)
TYPECAST(uint, ushort)
TYPECAST(uint, half)
TYPECAST(uint, float)

TYPECAST(half, char)
TYPECAST(half, short)
TYPECAST(half, int)
TYPECAST(half, uchar)
TYPECAST(half, ushort)
TYPECAST(half, uint)
TYPECAST(half, float)

TYPECAST(float, char)
TYPECAST(float, short)
TYPECAST(float, int)
TYPECAST(float, uchar)
TYPECAST(float, ushort)
TYPECAST(float, uint)
TYPECAST(float, half)
