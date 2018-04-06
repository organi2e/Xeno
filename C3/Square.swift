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
	let descriptor: MPSMatrixDescriptor
	let input: Sym
	var last: (MTLCommandBuffer, MTLBuffer)?
	init(x: Sym) throws {
		let length: Int = x.length
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues().binding(value: uint(length), for: "N")
		let library: MTLLibrary = try x.device.makeDefaultLibrary(bundle: Bundle(for: Square.self))
		let function: MTLFunction = try library.makeFunction(name: "square_" + x.xtype.description, constantValues: constantValues)
		input = x
		descriptor = MPSMatrixDescriptor(rows: x.rows, columns: x.columns, rowBytes: x.columns * x.xtype.stride, dataType: x.xtype.mpsType)
		pipeline = try x.device.makeComputePipelineState(function: function)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: ( length - 1 ) / threads.width + 1, height: 1, depth: 1)
	}
}
extension Square : Sym {
	var xtype: XType.Type {
		return input.xtype
	}
	var rows: Int {
		return input.rows
	}
	var columns: Int {
		return input.columns
	}
	var device: MTLDevice {
		return input.device
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		if let (command, buffer): (MTLCommandBuffer, MTLBuffer) = last, command === commandBuffer {
			return buffer
		} else {
			assert(commandBuffer.device === pipeline.device)
			let x: MTLBuffer = try input.eval(commandBuffer: commandBuffer)
			let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
			let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
			encoder.setComputePipelineState(pipeline)
			encoder.setBuffer(matrix.data, offset: 0, index: 0)
			encoder.setBuffer(x, offset: 0, index: 1)
			encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
			encoder.endEncoding()
			last = (commandBuffer, matrix.data)
			return matrix.data
		}
	}
}
public func square(_ x: Sym) throws -> Sym {
	return try Square(x: x)
}
