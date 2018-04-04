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
	if ( __index__ < \(__count__) ) dst [ __index__ ] = src [ __index__ ];
}
"""
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
		let descriptor: MPSMatrixCopyDescriptor = MPSMatrixCopyDescriptor.init(sourceMatrix: <#T##MPSMatrix#>, destinationMatrix: <#T##MPSMatrix#>, offsets: <#T##MPSMatrixCopyOffsets#>)
		kernel.encode(commandBuffer: commandBuffer, copyDescriptor: <#T##MPSMatrixCopyDescriptor#>)
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
