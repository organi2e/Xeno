//
//  Sum.swift
//  C3
//
//  Created by Kota Nakano on 4/5/18.
//
import Accelerate
import MetalPerformanceShaders
struct Sum {
//	let rows: Int
//	let columns: Int
//	let descriptor: MPSMatrixDescriptor
//	let kernel: MPSMatrixSum
//	let inputs: [Sym]
//	init(inputs x: [Sym]) throws {
//		guard let primary: Sym = x.first else {
//			throw ErrorCases.any
//		}
//	}
	init(inputs s: [Sym]) throws {
		
		
	}
}
/*
extension Sum {
	var rows: Int {
		return descriptor.rows
	}
	var columns: Int {
		return descriptor.columns
	}
	var device: MTLDevice {
		return kernel.device
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		let matrices: [MPSMatrix] = try inputs.map {
			try MPSMatrix(buffer: $0.eval(commandBuffer: commandBuffer), descriptor: descriptor)
		}
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
//		kernel.encode(to: commandBuffer, sourceMatrices: matrices, resultMatrix: matrix, scale: nil, offsetVector: nil, biasVector: nil, start: 0)
		return matrix.data
	}
}
*/
public func sum(_ s: [Sym]) throws {
	let rows: Int = s.reduce(0) { max($0, $1.rows) }
	let columns: Int = s.reduce(0) { max($0, $1.columns) }
}
