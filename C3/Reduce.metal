//
//  Reduce.metal
//  C3
//
//  Created by Kota Nakano on 4/11/18.
//
#include <metal_stdlib>
using namespace metal;
constant uint const rows [[ function_constant(0) ]];
constant uint const columns [[ function_constant(1) ]];
kernel void reduce_rows_sum_float(device float * const y [[ buffer(0) ]],
								 device float const * const x [[ buffer(1) ]],
								 uint const index [[ thread_position_in_grid ]]) {
	if ( index < columns ) {
		thread float sum = 0;
		for ( uint k = index, K = rows * columns ; k < K ; k += columns ) sum += x [ k ];
		y [ index ] = sum;
	}
}
kernel void reduce_rows_mean_float(device float * const y [[ buffer(0) ]],
								   device float const * const x [[ buffer(1) ]],
								   uint const index [[ thread_position_in_grid ]]) {
	if ( index < columns ) {
		thread float sum = 0;
		device float const * ref = x + index;
		for ( uint k = 0, K = rows ; k < K ; ++ k, ref += columns ) sum += * ref;
		y [ index ] = sum / float(rows);
	}
}
kernel void reduce_columns_sum_float(device float * const y [[ buffer(0) ]],
								 device float const * const x [[ buffer(1) ]],
								 uint const index [[ thread_position_in_grid ]]) {
	if ( index < rows ) {
		thread float sum = 0;
		device float const * ref = x + index * columns;
		for ( uint k = 0, K = columns ; k < K ; ++ k, ++ ref ) sum += * ref;
		y [ index ] = sum;
	}
}
kernel void reduce_columns_mean_float(device float * const y [[ buffer(0) ]],
									  device float const * const x [[ buffer(1) ]],
									  uint const index [[ thread_position_in_grid ]]) {
	if ( index < rows ) {
		thread float sum = 0;
		device float const * ref = x + index * columns;
		for ( uint k = 0, K = columns ; k < K ; ++ k, ++ ref ) sum += * ref;
		y [ index ] = sum / float(columns);
	}
}
