//
//  Repeating.swift
//  C3
//
//  Created by Kota Nakano on 4/11/18.
//
import MetalPerformanceShaders
struct Repeating {
	let descriptor: MPSMatrixDescriptor
	let source: Sym
	let pipeline: MTLComputePipelineState
	let threads:MTLSize
	let groups: MTLSize
	init(rowTimes: Int, columnTimes: Int, source s: Sym) throws {
		let t_rows: Int = rowTimes * s.rows
		let t_columns: Int = columnTimes * s.columns
		let length: Int = t_rows * t_columns
		let device: MTLDevice = s.device
		let library: MTLLibrary = try device.makeDefaultLibrary(bundle: Bundle(for: Context.self))
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues()
			.binding(value: uint(t_rows), for: "target_rows")
			.binding(value: uint(s.rows), for: "source_rows")
			.binding(value: uint(t_columns), for: "target_columns")
			.binding(value: uint(s.columns), for: "source_columns")
		let function: MTLFunction = try library.makeFunction(name: "repeating_\(s.xtype.description)", constantValues: constantValues)
		pipeline = try device.makeComputePipelineState(function: function)
		source = s
		descriptor = MPSMatrixDescriptor(rows: t_rows, columns: t_columns, rowBytes: t_columns * s.xtype.stride, dataType: s.xtype.mpsType)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension Repeating: Sym {
	var rows: Int {
		return descriptor.rows
	}
	var columns: Int {
		return descriptor.columns
	}
	var xtype: XType.Type {
		return source.xtype
	}
	var device: MTLDevice {
		return pipeline.device
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		assert( commandBuffer.device === pipeline.device )
		let buffer: MTLBuffer = try source.eval(commandBuffer: commandBuffer)
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
public func repeating(_ source: Sym, _ times: (Int, Int)) throws -> Sym {
	assert( 0 < times.0 )
	assert( 0 < times.1 )
	return try Repeating(rowTimes: times.0, columnTimes: times.1, source: source)
}
