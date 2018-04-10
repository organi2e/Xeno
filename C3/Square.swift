//
//  Square.swift
//  C3
//
//  Created by Kota Nakano on 4/3/18.
//
import Accelerate
import MetalPerformanceShaders
struct Square {
	let descriptor: MPSMatrixDescriptor
	let pipeline: MTLComputePipelineState
	let input: Sym
	let groups: MTLSize
	let threads: MTLSize
	init(x: Sym) throws {
		let length: Int = x.rows * x.columns
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues().binding(value: uint(length), for: "count")
		let library: MTLLibrary = try x.device.makeDefaultLibrary(bundle: Bundle(for: Context.self))
		let function: MTLFunction = try library.makeFunction(name: "square_" + x.xtype.description, constantValues: constantValues)
		descriptor = MPSMatrixDescriptor(rows: x.rows, columns: x.columns, rowBytes: x.columns * x.xtype.stride, dataType: x.xtype.mpsType)
		pipeline = try x.device.makeComputePipelineState(function: function)
		input = x
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
		assert(commandBuffer.device === pipeline.device)
		let buffer: MTLBuffer = try input.eval(commandBuffer: commandBuffer)
		let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		encoder.setComputePipelineState(pipeline)
		encoder.setBuffer(matrix.data, offset: 0, index: 0)
		encoder.setBuffer(buffer, offset: 0, index: 1)
		encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
		return matrix.data
	}
}
public func square(_ x: Sym) throws -> Sym {
	return try Square(x: x)
}
