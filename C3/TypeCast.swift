//
//  TypeCast.swift
//  C3
//
//  Created by Kota Nakano on 4/5/18.
//
import MetalPerformanceShaders
struct TypeCast {
	let xtype: XType.Type
	let descriptor: MPSMatrixDescriptor
	let pipeline: MTLComputePipelineState
	let input: Sym
	let threads: MTLSize
	let groups: MTLSize
	init(as t: XType.Type, source: Sym) throws {
		let device: MTLDevice = source.device
		let rows: Int = source.rows
		let columns: Int = source.columns
		let length: Int = rows * columns
		let library: MTLLibrary = try device.makeDefaultLibrary(bundle: Bundle(for: Context.self))
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues()
			.binding(value: uint(length), for: "count")
		let function: MTLFunction = try library.makeFunction(name: "typecast_\(t.description)_\(source.xtype.description)", constantValues: constantValues)
		xtype = t
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * t.stride, dataType: t.mpsType)
		pipeline = try device.makeComputePipelineState(function: function)
		input = source
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension TypeCast: Sym {
	var rows: Int {
		return descriptor.rows
	}
	var columns: Int {
		return descriptor.columns
	}
	var device: MTLDevice {
		return pipeline.device
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		let source: MTLBuffer = try input.eval(commandBuffer: commandBuffer)
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
		encoder.setComputePipelineState(pipeline)
		encoder.setBuffer(matrix.data, offset: 0, index: 0)
		encoder.setBuffer(source, offset: 0, index: 1)
		encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
		return matrix.data
	}
}
public func typecast(as type: XType.Type, _ source: Sym) throws -> Sym {
	return try TypeCast(as: type, source: source)
}
/*
private let __kernel__: String = "__typecast__"
private let __index__: String = "__index__"
private let __count__: String = "__count__"
private let __srctype__: String = "__srctype__"
private let __dsttype__: String = "__dsttype__"
private let __template__: String = """
using namespace metal;
constant uint \(__count__) [[ function_constant(0) ]];
kernel void \(__kernel__)(
	device \(__dsttype__) * const dst [[ buffer(0) ]],
	device \(__srctype__) const * const src [[ buffer(1) ]],
	uint const __index__ [[ thread_position_in_grid ]]) {
	if ( \(__index__) < \(__count__) ) dst [ \(__index__) ] = src [ \(__index__) ];
}
"""
struct TypeCast<X> where X : XType {
	let descriptor: MPSMatrixDescriptor
	let input: Sym
	let pipeline: MTLComputePipelineState
	let groups: MTLSize
	let threads: MTLSize
	init(input x: Sym) throws {
		let length: Int = x.length
		let code: String = __template__
			.replacingOccurrences(of: __dsttype__, with: X.description)
			.replacingOccurrences(of: __srctype__, with: x.xtype.description)
		let library: MTLLibrary = try x.device.makeLibrary(source: code, options: nil)
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues().binding(value: uint(length), for: __count__)
		let function: MTLFunction = try library.makeFunction(name: __kernel__, constantValues: constantValues)
		descriptor = MPSMatrixDescriptor(rows: x.rows, columns: x.columns, rowBytes: x.columns * X.stride, dataType: X.mpsType)
		input = x
		pipeline = try x.device.makeComputePipelineState(function: function)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension TypeCast : Sym {
	var xtype: XType.Type {
		return X.self
	}
	var rows: Int {
		return descriptor.rows
	}
	var columns: Int {
		return descriptor.columns
	}
	var device: MTLDevice {
		return pipeline.device
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		assert(commandBuffer.device === pipeline.device)
		let buffer: MTLBuffer = try input.eval(commandBuffer: commandBuffer)
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
		encoder.setComputePipelineState(pipeline)
		encoder.setBuffer(matrix.data, offset: 0, index: 0)
		encoder.setBuffer(buffer, offset: 0, index: 1)
		encoder.dispatchThreads(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
		return matrix.data
	}
}
public func typecast<X>(as: X.Type, _ input: Sym) throws -> Sym where X : XType {
	return try TypeCast<X>(input: input)
}
*/
