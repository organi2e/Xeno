//
//  Copy.swift
//  C3
//
//  Created by Kota Nakano on 4/3/18.
//
import MetalPerformanceShaders
struct ByteCopy {
	let dst: Sym
	let src: Sym
}
extension ByteCopy : Task {
	public func eval(commandBuffer: MTLCommandBuffer) throws {
		assert( src.xtype == dst.xtype )
		assert( (src.rows, src.columns) == (dst.rows, dst.columns) )
		let from: MTLBuffer = try src.eval(commandBuffer: commandBuffer)
		let to: MTLBuffer = try dst.eval(commandBuffer: commandBuffer)
		let encoder: MTLBlitCommandEncoder = try commandBuffer.makeBlitCommandEncoder()
		encoder.copy(from: from, sourceOffset: 0, to: to, destinationOffset: 0, size: min(from.length, to.length))
		encoder.endEncoding()
	}
}
struct TypeCastCopy {
	let xtype: XType.Type
	let descriptor: MPSMatrixDescriptor
	let pipeline: MTLComputePipelineState
	let threads: MTLSize
	let groups: MTLSize
	let to: Sym
	let from: Sym
	init(target: Sym, source: Sym) throws {
		
		assert( target.device === source.device )
		assert( target.xtype != source.xtype )
		assert( ( target.rows, target.columns ) == ( source.rows, source.columns ) )
		
		let device: MTLDevice = target.device
		let rows: Int = target.rows
		let columns: Int = target.columns
		let length: Int = rows * columns
		let library: MTLLibrary = try device.makeDefaultLibrary(bundle: Bundle(for: Context.self))
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues()
			.binding(value: uint(length), for: "count")
		let function: MTLFunction = try library.makeFunction(name: "typecast_\(target.xtype.description)_\(source.xtype.description)", constantValues: constantValues)
		xtype = target.xtype
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * xtype.stride, dataType: xtype.mpsType)
		pipeline = try device.makeComputePipelineState(function: function)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
		to = target
		from = source
	}
}
/*
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
*/
extension TypeCastCopy : Task {
	public func eval(commandBuffer: MTLCommandBuffer) throws {
		assert(pipeline.device === commandBuffer.device)
		let target: MTLBuffer = try to.eval(commandBuffer: commandBuffer)
		let source: MTLBuffer = try from.eval(commandBuffer: commandBuffer)
		let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
		encoder.setComputePipelineState(pipeline)
		encoder.setBuffer(target, offset: 0, index: 0)
		encoder.setBuffer(source, offset: 0, index: 1)
		encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
	}
}
public func store(to dst: Sym, from src: Sym) throws -> Task {
	assert( dst.device === src.device )
	assert( ( dst.rows, dst.columns ) == ( src.rows, src.columns ) )
	if src.xtype == dst.xtype {
		return ByteCopy(dst: dst, src: src)
	} else {
		return try TypeCastCopy(target: dst, source: src)
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
