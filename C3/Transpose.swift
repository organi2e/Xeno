//
//  Transpose.swift
//  C3
//
//  Created by Kota Nakano on 4/5/18.
//
import Accelerate
import MetalPerformanceShaders
struct TransposedVector {
	let input: Sym
	init(input x: Sym) {
		input = x
	}
}
extension TransposedVector : Sym {
	var device: MTLDevice {
		return input.device
	}
	var rows: Int {
		return input.columns
	}
	var columns: Int {
		return input.rows
	}
	var xtype: XType.Type {
		return input.xtype
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		return try input.eval(commandBuffer: commandBuffer)
	}
}
struct TransposedMatrix {
	let input: Sym
	let descriptor: MPSMatrixDescriptor
	let kernel: MPSMatrixCopy
	let offsets: MPSMatrixCopyOffsets
	init(input x: Sym) {
		input = x
		descriptor = MPSMatrixDescriptor(rows: x.columns, columns: x.rows, rowBytes: x.rows * x.xtype.stride, dataType: x.xtype.mpsType)
		kernel = MPSMatrixCopy(device: x.device, copyRows: x.rows, copyColumns: x.columns, sourcesAreTransposed: false, destinationsAreTransposed: true)
		offsets = MPSMatrixCopyOffsets(sourceRowOffset: 0, sourceColumnOffset: 0, destinationRowOffset: 0, destinationColumnOffset: 0)
	}
}
extension TransposedMatrix : Sym {
	var device: MTLDevice {
		return kernel.device
	}
	var rows: Int {
		return descriptor.rows
	}
	var columns: Int {
		return descriptor.columns
	}
	var xtype: XType.Type {
		return input.xtype
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		assert(commandBuffer.device === kernel.device)
		let source: MPSMatrix = try MPSMatrix(buffer: input.eval(commandBuffer: commandBuffer), descriptor: input.descriptor)
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		kernel.encode(commandBuffer: commandBuffer, copyDescriptor: MPSMatrixCopyDescriptor(sourceMatrix: source, destinationMatrix: matrix, offsets: offsets))
		return matrix.data
	}
}
public func transpose(_ input: Sym) -> Sym {
	switch (input.rows, input.columns) {
	case (1, _), (_, 1):
		return TransposedVector(input: input)
	default:
		return TransposedMatrix(input: input)
	}
}
