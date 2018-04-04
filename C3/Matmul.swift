//
//  Matmul.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import MetalPerformanceShaders
public protocol Matmul {
	
}
/*
class GEMM {
	let rows: Int
	let columns: Int
	let interior: Int
	let symbols: (Symbol, Symbol)
	let mpskernel: MPSMatrixMultiplication
	init(_ l: Symbol, _ r: Symbol) {
		assert( l.columns == r.rows )
		assert( l.device === r.device )
		rows = l.rows
		columns = r.columns
		interior = l.columns
		symbols = (l, r)
		mpskernel = MPSMatrixMultiplication(device: l.device, resultRows: rows, resultColumns: columns, interiorColumns: interior)
	}
}
class GEMV {
	let rows: Int
	let columns: Int
	let symbols: (Symbol, Symbol)
	let mpskernel: MPSMatrixVectorMultiplication
	init(_ l: Symbol, _ r: Symbol) {
		assert( l.columns == r.rows )
		assert( r.columns == 1 )
		assert( l.device === r.device )
		rows = l.rows
		columns = r.columns
		symbols = (l, r)
		mpskernel = MPSMatrixVectorMultiplication(device: l.device, rows: rows, columns: columns)
	}
}
*/
