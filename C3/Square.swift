//
//  Square.swift
//  C3
//
//  Created by Kota Nakano on 4/3/18.
//
import Accelerate
import MetalPerformanceShaders
class Square {
	let pipeline: MTLComputePipelineState
	let groups: MTLSize
	let threads: MTLSize
	let count: Int
	let rows: Int
	let columns: Int
	let descriptor: MPSMatrixDescriptor
	let input: Symbol
	var evaluated: (MTLCommandBuffer, MPSTemporaryMatrix)?
	init(x: Symbol) throws {
		input = x
		count = x.count
		rows = x.rows
		columns = x.columns
		let length: Int = count * rows * columns
		let device: MTLDevice = x.device
		let library: MTLLibrary = try device.makeDefaultLibrary(bundle: Bundle(for: Square.self))
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues().binding(value: uint(length), for: "N")
		let function: MTLFunction = try library.makeFunction(name: "square_" + x.type.description, constantValues: constantValues)
		let rowBytes: Int = columns * x.type.stride
		let matrixBytes: Int = rows * rowBytes
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, matrices: count, rowBytes: rowBytes, matrixBytes: matrixBytes, dataType: x.type.mpsType)
		pipeline = try device.makeComputePipelineState(function: function)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: ( length - 1 ) / threads.width + 1, height: 1, depth: 1)
	}
}
extension Square : Symbol {
	func eval(commandBuffer: MTLCommandBuffer) throws -> MPSArray {
		if let (previous, matrix) = evaluated, previous === commandBuffer {
			return matrix
		}
		let array: MPSArray = try input.eval(commandBuffer: commandBuffer)
		guard let encoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else {
			throw ErrorCases.any
		}
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		encoder.setComputePipelineState(pipeline)
		encoder.setBuffer(matrix.data, offset: 0, index: 0)
		encoder.setBuffer(array.data, offset: 0, index: 1)
		encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
		evaluated = (commandBuffer, matrix)
		return matrix
	}
	var device: MTLDevice {
		return pipeline.device
	}
	var transpose: Bool {
		return input.transpose
	}
	var type: MPSType.Type {
		return input.type
	}
}
public func square(_ x: Symbol) throws -> Symbol {
	return try Square(x: x)
}
