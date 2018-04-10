//
//  Uniform.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import Accelerate
import MetalPerformanceShaders
struct IntegerUniform<I> where I : XType, I : XInteger {
	let descriptor: MPSMatrixDescriptor
	let buffer: MTLBuffer
	let group: DispatchGroup
	init(device: MTLDevice, rows: Int, columns: Int) throws {
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * I.stride, dataType: I.mpsType)
		buffer = try device.makeBuffer(length: rows * columns * I.stride, options: .storageModeShared)
		group = DispatchGroup()
		shuffle()
	}
}
extension IntegerUniform {
	private func imp() {
		arc4random_buf(buffer.contents(), buffer.length)
	}
	func shuffle() {
		group.wait()
		DispatchQueue.global().async(group: group, execute: imp)
	}
}
extension IntegerUniform: Sym {
	private func cmp(_: MTLCommandBuffer) {
		shuffle()
	}
	var xtype: XType.Type {
		return I.self
	}
	var rows: Int {
		return descriptor.rows
	}
	var columns: Int {
		return descriptor.columns
	}
	var device: MTLDevice {
		return buffer.device
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		commandBuffer.addCompletedHandler(cmp)
		return buffer
	}
}
struct BinaryUniform {
	let xtype: XType.Type
	let rows: Int
	let columns: Int
	let buffer: MTLBuffer
	let group: DispatchGroup
	init(context x: Context, xtype t: XType.Type, rows r: Int, columns c: Int) throws {
		assert({switch $0{
		case is Int8.Type, is Int16.Type, is Int32.Type, is UInt8.Type, is UInt16.Type, is UInt32.Type:
			return true
		default:
			return false
		}}(t))
		xtype = t
		rows = r
		columns = c
		buffer = try x.device.makeBuffer(length: rows * columns * xtype.stride, options: .storageModeShared)
		group = DispatchGroup()
		shuffle()
	}
}
extension BinaryUniform {
	private func implementation() {
		arc4random_buf(buffer.contents(), buffer.length)
	}
	func shuffle() {
		group.wait()
		DispatchQueue.global().async(group: group, execute: implementation)
	}
}
extension BinaryUniform: Sym {
	private func complete(_: MTLCommandBuffer) {
		shuffle()
	}
	var device: MTLDevice {
		return buffer.device
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		commandBuffer.addCompletedHandler(complete)
		return buffer
	}
}
struct Uniform<F, I> where F : XType, F : XFloat, I : XType, I : XInteger {
	let descriptor: MPSMatrixDescriptor
	let pipeline: MTLComputePipelineState
	let uniform: IntegerUniform<I>
	let threads: MTLSize
	let groups: MTLSize
	init(library: MTLLibrary, rows: Int, columns: Int) throws {
		let device: MTLDevice = library.device
		let length: Int = rows * columns
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues()
			.binding(value: uint(length), for: "count")
		let library: MTLLibrary = try device.makeDefaultLibrary(bundle: Bundle(for: Context.self))
		let function: MTLFunction = try library.makeFunction(name: "normalize_\(F.description)_\(I.description)", constantValues: constantValues)
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * F.stride, dataType: F.mpsType)
		pipeline = try device.makeComputePipelineState(function: function)
		uniform = try IntegerUniform<I>(device: device, rows: rows, columns: columns)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension Uniform: Sym {
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
struct FloatingUniform {
	let xtype: XType.Type
	let descriptor: MPSMatrixDescriptor
	let uniform: Sym
	let pipeline: MTLComputePipelineState
	let threads: MTLSize
	let groups: MTLSize
	init(library: MTLLibrary, xtype t: XType.Type, rows: Int, columns: Int) throws {
		switch t {
		case is Float16.Type:
			uniform = try IntegerUniform<UInt8>(device: library.device, rows: rows, columns: columns)
		case is Float32.Type:
			uniform = try IntegerUniform<UInt16>(device: library.device, rows: rows, columns: columns)
		default:
			assertionFailure()
			throw ErrorCases.any
		}
		let length: Int = rows * columns
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues().binding(value: uint(length), for: "count")
		let function: MTLFunction = try library.makeFunction(name: "normalize_\(t.description)_\(uniform.xtype.description)", constantValues: constantValues)
		xtype = t
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * t.stride, dataType: t.mpsType)
		pipeline = try library.device.makeComputePipelineState(function: function)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension FloatingUniform: Sym {
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
	func makeUniform(type: XType.Type, rows: Int, columns: Int) throws -> Sym {
		switch type {
		case is UInt8.Type:
			return try IntegerUniform<UInt8>(device: device, rows: rows, columns: columns)
		case is UInt16.Type:
			return try IntegerUniform<UInt16>(device: device, rows: rows, columns: columns)
		case is UInt32.Type:
			return try IntegerUniform<UInt32>(device: device, rows: rows, columns: columns)
		case is Int8.Type:
			return try IntegerUniform<Int8>(device: device, rows: rows, columns: columns)
		case is Int16.Type:
			return try IntegerUniform<Int16>(device: device, rows: rows, columns: columns)
		case is Float16.Type:
			return try Uniform<Float16, UInt8>(library: library, rows: rows, columns: columns)
		case is Float32.Type:
			return try Uniform<Float32, UInt16>(library: library, rows: rows, columns: columns)
		default:
			assertionFailure()
			throw ErrorCases.any
		}
	}
}

/*
struct IntegerUniform<X> where X : XType, X : BinaryInteger {
	let rows: Int
	let columns: Int
	let buffer: MTLBuffer
	let queue: DispatchQueue
	let group: DispatchGroup
	init(device: MTLDevice, rows r: Int, columns c: Int) throws {
		assert( X.self is  Int8.Type || X.self is  Int16.Type || X.self is  Int32.Type ||
				X.self is UInt8.Type || X.self is UInt16.Type || X.self is UInt32.Type )
		rows = r
		columns = c
		buffer = try device.makeBuffer(length: rows * columns * X.stride, options: .storageModeShared)
		queue = .global(qos: .default)
		group = DispatchGroup()
		shuffle()
	}
}
extension IntegerUniform {
	private func implementation() {
		arc4random_buf(buffer.contents(), buffer.length)
	}
	func shuffle() {
		group.wait()
		queue.async(group: group, execute: implementation)
	}
}
struct FloatingUniform<X> where X : XType, X : FloatingPoint {
	let x: Int
	init(library: MTLLibrary) throws where X.Type is Float16.Type {
		x = 0
	}
}
struct Float16Uniform {
	let descriptor: MPSMatrixDescriptor
	let u: IntegerUniform<UInt8>
	let p: MTLComputePipelineState
	init(library: MTLLibrary, rows: Int, columns: Int) throws {
		let length: Int = rows * columns
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues.init().binding(value: uint(length), for: "count")
		let function: MTLFunction = try library.makeFunction(name: "uniform_half_uchar", constantValues: constantValues)
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns, dataType: .float16)
		u = try IntegerUniform<UInt8>(device: library.device, rows: rows, columns: columns)
		p = try library.device.makeComputePipelineState(function: function)
	}
}
struct Float32Uniform {
	let u: IntegerUniform<UInt16>
	init(device: MTLDevice, rows: Int, columns: Int) throws {
		u = try IntegerUniform<UInt16>(device: device, rows: rows, columns: columns)
	}
}
extension IntegerUniform : Sym {
	private func complete(_: MTLCommandBuffer) {
		shuffle()
	}
	var device: MTLDevice {
		return buffer.device
	}
	var xtype: XType.Type {
		return X.self
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		commandBuffer.addCompletedHandler(complete)
		return buffer
	}
}
/*
extension Context {
	public func makeUniform(type: XType.Type, rows: Int, columns: Int) throws -> Sym {
		switch type {
		case is Float16.Type:
			let u: Sym = try IntegerUniform<UInt8>(device: device, rows: rows, columns: columns)
			return try map(type: type, lambda: "( u + 0.5 ) / 256.0", source: ["u": u])
		case is Float32.Type:
			let u: Sym = try IntegerUniform<UInt16>(device: device, rows: rows, columns: columns)
			return try map(type: type, lambda: "( u + 0.5 ) / 65536.0", source: ["u": u])
		case is UInt8.Type:
			return try IntegerUniform<UInt8>(device: device, rows: rows, columns: columns)
		default:
			throw ErrorCases.any
		}
	}
}
*/
*/
