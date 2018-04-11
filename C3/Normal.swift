//
//  Normal.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import MetalPerformanceShaders
struct NormalRNG<F, S> where F : XType, F : XFloat, S : XType, S : XInteger {
	let uniform: Sym
	let descriptor: MPSMatrixDescriptor
	let pipeline: MTLComputePipelineState
	let threads: MTLSize
	let groups: MTLSize
	init(device: MTLDevice, rows: Int, columns: Int) throws {
		let length: Int = rows * columns
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues()
			.binding(value: uint(length), for: "count")
		let library: MTLLibrary = try device.makeDefaultLibrary(bundle: Bundle(for: Context.self))
		let function: MTLFunction = try library.makeFunction(name: "normal_rng_\(F.description)_\(S.description)", constantValues: constantValues)
		uniform = try IntegerUniform<S>(device: device, rows: rows, columns: columns)
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * F.stride, dataType: F.mpsType)
		pipeline = try device.makeComputePipelineState(function: function)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension NormalRNG : Sym {
	var rows: Int {
		return descriptor.rows
	}
	var columns: Int {
		return descriptor.columns
	}
	var xtype: XType.Type {
		return F.self
	}
	var device: MTLDevice {
		return pipeline.device
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		let buffer: MTLBuffer = try uniform.eval(commandBuffer: commandBuffer)
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
		encoder.setComputePipelineState(pipeline)
		encoder.setBuffer(matrix.data, offset: 0, index: 0)
		encoder.setBuffer(buffer, offset: 0, index: 1)
		encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
		return matrix.data
	}
}
extension Context {
	func makeStdNormal(type: XType.Type,  rows: Int, columns: Int) throws -> Sym {
		switch type {
		case is Float16.Type:
			return try NormalRNG<Float16, Int8>(device: device, rows: rows, columns: columns)
		case is Float32.Type:
			return try NormalRNG<Float32, Int16>(device: device, rows: rows, columns: columns)
		default:
			throw ErrorCases.any
		}
	}
}
