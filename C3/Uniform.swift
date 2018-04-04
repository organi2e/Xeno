//
//  Uniform.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import Accelerate
import MetalPerformanceShaders
public protocol Uniform {
	
}
struct MPSUniform {
	let count: Int
	let rows: Int
	let columns: Int
	let dataType: MPSDataType
}
extension MPSUniform {
	func eval(commandBuffer: MTLCommandBuffer) throws {
//		let rowBytes: Int = columns * dataType.strid
//		let matrixBytes: Int = rows * rowBytes
//		let descriptor: MPSMatrixDescriptor = MPSMatrixDescriptor(rows: rows, columns: columns, matrices: count, rowBytes: rowBytes, matrixBytes: matrixBytes, dataType: dataType)
//		let result: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
//		print(result.data.storageMode == MTLStorageMode.memoryless)
//		print(result.data.storageMode == .shared)
//		print(result.data.storageMode == .private)
	}
}

