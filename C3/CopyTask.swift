//
//  Copy.swift
//  C3
//
//  Created by Kota Nakano on 4/3/18.
//
import Accelerate
import MetalPerformanceShaders
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
struct ByteCopy {
	let src: Sym
	let dst: Sym
}
extension ByteCopy : Task {
	public func eval(commandBuffer: MTLCommandBuffer) throws {
		let from: MTLBuffer = try src.eval(commandBuffer: commandBuffer)
		let to: MTLBuffer = try dst.eval(commandBuffer: commandBuffer)
		assert(from.length == to.length)
		let encoder: MTLBlitCommandEncoder = try commandBuffer.makeBlitCommandEncoder()
		encoder.copy(from: from, sourceOffset: 0, to: to, destinationOffset: 0, size: min(from.length, to.length))
		encoder.endEncoding()
	}
}
struct TypeCastCopy {
	let pipeline: MTLComputePipelineState
	let src: Sym
	let dst: Sym
	let threads: MTLSize
	let groups: MTLSize
	init(src s: Sym, dst d: Sym) throws {
		let count: Int = min(s.length, d.length)
		let code: String = __template__
			.replacingOccurrences(of: __srctype__, with: s.xtype.description)
			.replacingOccurrences(of: __dsttype__, with: d.xtype.description)
		let library: MTLLibrary = try s.device.makeLibrary(source: code, options: nil)
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues().binding(value: uint(count), for: __count__)
		let function: MTLFunction = try library.makeFunction(name: __kernel__, constantValues: constantValues)
		pipeline = try d.device.makeComputePipelineState(function: function)
		src = s
		dst = d
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (count-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension TypeCastCopy : Task {
	public func eval(commandBuffer: MTLCommandBuffer) throws {
		assert(pipeline.device === commandBuffer.device)
		let from: MTLBuffer = try src.eval(commandBuffer: commandBuffer)
		let to: MTLBuffer = try dst.eval(commandBuffer: commandBuffer)
		let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
		encoder.setComputePipelineState(pipeline)
		encoder.setBuffer(to, offset: 0, index: 0)
		encoder.setBuffer(from, offset: 0, index: 1)
		encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
	}
}
public func store(to dst: Sym, from src: Sym) throws -> Task {
	assert(src.device === dst.device)
	assert(src.rows == dst.rows)
	assert(src.columns == dst.columns)
	if src.xtype == dst.xtype {
		return ByteCopy(src: src, dst: dst)
	} else {
		return try TypeCastCopy(src: src, dst: dst)
	}
}
/*
struct ByteCopyTask {
	let src: Symbol
	let dst: Symbol
}
extension ByteCopyTask: Task {
	func execute(commandBuffer: MTLCommandBuffer) throws {
		assert(src.count == dst.count)
		assert(src.rows == dst.rows)
		assert(src.columns == dst.columns)
		assert(src.type == dst.type)
		let from: MPSArray = try src.eval(commandBuffer: commandBuffer)
		let to: MPSArray = try dst.eval(commandBuffer: commandBuffer)
		guard let encoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder() else {
			throw ErrorCases.any
		}
		let srcSize: Int = src.count * src.rows * src.columns * src.type.stride
		let dstSize: Int = dst.count * dst.rows * dst.columns * dst.type.stride
		let size: Int = min(srcSize, dstSize)
		encoder.copy(from: from.data, sourceOffset: 0, to: to.data, destinationOffset: 0, size: size)
		encoder.endEncoding()
	}
}
struct MatrixCopy {
	let kernel: MPSMatrixCopy
	let src: Symbol
	let dst: Symbol
}
extension MatrixCopy {
	func execute(commandBuffer: MTLCommandBuffer) throws {
		let from: MPSArray = try src.eval(commandBuffer: commandBuffer)
		let to: MPSArray = try dst.eval(commandBuffer: commandBuffer)
	}
}
struct TypeCastTask{
	let src: Symbol
	let dst: Symbol
	let pipeline: MTLComputePipelineState
	let groups: MTLSize
	let threads: MTLSize
}
extension TypeCastTask: Task {
	func execute(commandBuffer: MTLCommandBuffer) throws {
		assert(src.count == dst.count)
		assert(src.rows == dst.rows)
		assert(src.columns == dst.columns)
		assert(src.type == dst.type)
		let from: MPSArray = try src.eval(commandBuffer: commandBuffer)
		let to: MPSArray = try dst.eval(commandBuffer: commandBuffer)
		let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
		encoder.setComputePipelineState(pipeline)
		encoder.setBuffer(to.data, offset: 0, index: 0)
		encoder.setBuffer(from.data, offset: 0, index: 1)
		encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
	}
}
func copy(from: Symbol, to: Symbol) throws -> Task {
	assert(from.device === to.device)
	assert(from.count == to.count)
	assert(from.rows == to.rows)
	assert(from.columns == to.columns)
	let length: Int = from.count * from.rows * from.columns
	let device: MTLDevice = from.device
	if from.type == to.type {
		let kernel: MPSMatrixCopy = MPSMatrixCopy(device: from.device, copyRows: from.rows, copyColumns: from.columns, sourcesAreTransposed: from.transpose, destinationsAreTransposed: to.transpose)
		
		return ByteCopyTask(src: from, dst: to)
	} else {
		let code: String = __template__
			.replacingOccurrences(of: __dsttype__, with: to.type.description)
			.replacingOccurrences(of: __srctype__, with: from.type.description)
		let library: MTLLibrary = try device.makeLibrary(source: code, options: nil)
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues().binding(value: uint(), for: __count__)
		let function: MTLFunction = try library.makeFunction(name: __kernel__, constantValues: constantValues)
		let pipeline: MTLComputePipelineState = try device.makeComputePipelineState(function: function)
		return ByteCopyTask(src: from, dst: to)
	}
}
*/
