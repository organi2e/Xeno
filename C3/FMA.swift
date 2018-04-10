//
//  FMA.swift
//  C3
//
//  Created by Kota Nakano on 4/10/18.
//
import MetalPerformanceShaders
struct FMAVSS<F> where F : XType, F : XFloat {
	let xtype: XType.Type
	let descriptor: MPSMatrixDescriptor
	let pipeline: MTLComputePipelineState
	let input: Sym
	let threads: MTLSize
	let groups: MTLSize
	init(x: Sym, a: F, b: F) throws {
		assert( x.xtype == F.self )
		let device: MTLDevice = x.device
		let rows: Int = x.rows
		let columns: Int = x.columns
		let length: Int = rows * columns
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues()
			.binding(value: uint(length), for: "count")
			.binding(value: a, for: "a_\(F.description)")
			.binding(value: b, for: "b_\(F.description)")
		let library: MTLLibrary = try device.makeDefaultLibrary(bundle: Bundle(for: Context.self))
		let function: MTLFunction = try library.makeFunction(name: "FMAVSS_\(F.description)", constantValues: constantValues)
		xtype = x.xtype
		descriptor = MPSMatrixDescriptor.init(rows: rows, columns: columns, rowBytes: columns * xtype.stride, dataType: xtype.mpsType)
		pipeline = try device.makeComputePipelineState(function: function)
		input = x
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension FMAVSS: Sym {
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
		let buffer: MTLBuffer = try input.eval(commandBuffer: commandBuffer)
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
struct FMAVSV<F> where F : XType, F : XFloat {
	let descriptor: MPSMatrixDescriptor
	let pipeline: MTLComputePipelineState
	let inputs: [Sym]
	let offsets: [Int]
	let range: Range<Int>
	let threads: MTLSize
	let groups: MTLSize
	init(x: Sym, a: F, b: Sym) throws {
		
		assert( x.device === b.device )
		assert( ( x.rows, x.columns ) == ( b.rows, b.columns ) )
		assert( x.xtype == F.self )
		assert( b.xtype == F.self )
		
		let device: MTLDevice = x.device
		let rows: Int = x.rows
		let columns: Int = x.columns
		let length: Int = rows * columns
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues()
			.binding(value: uint(length), for: "count")
			.binding(value: a, for: "a_\(F.description)")
		let library: MTLLibrary = try device.makeDefaultLibrary(bundle: Bundle(for: Context.self))
		let function: MTLFunction = try library.makeFunction(name: "FMAVSV_\(F.description)", constantValues: constantValues)
		
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * F.stride, dataType: F.mpsType)
		pipeline = try device.makeComputePipelineState(function: function)
		inputs = [x, b]
		offsets = Array<Int>(repeating: 0, count: inputs.count)
		range = 1..<(1+inputs.count)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension FMAVSV: Sym {
	var xtype: XType.Type {
		return F.self
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
		let buffers: [MTLBuffer] = try inputs.map { try $0.eval(commandBuffer: commandBuffer) }
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
		encoder.setComputePipelineState(pipeline)
		encoder.setBuffer(matrix.data, offset: 0, index: 0)
		encoder.setBuffers(buffers, offsets: offsets, range: range)
		encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
		return matrix.data
	}
}

struct FMAVVS<F> where F : XType, F : XFloat {
	let descriptor: MPSMatrixDescriptor
	let pipeline: MTLComputePipelineState
	let inputs: [Sym]
	let offsets: [Int]
	let range: Range<Int>
	let threads: MTLSize
	let groups: MTLSize
	init(x: Sym, a: Sym, b: F) throws {
		
		assert( x.device === a.device )
		assert( ( x.rows, x.columns ) == ( a.rows, a.columns ) )
		assert( x.xtype == F.self )
		assert( a.xtype == F.self )
		
		let device: MTLDevice = x.device
		let rows: Int = x.rows
		let columns: Int = x.columns
		let length: Int = rows * columns
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues()
			.binding(value: uint(length), for: "count")
			.binding(value: b, for: "b_\(F.description)")
		let library: MTLLibrary = try device.makeDefaultLibrary(bundle: Bundle(for: Context.self))
		let function: MTLFunction = try library.makeFunction(name: "FMAVVS_\(F.description)", constantValues: constantValues)
		
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * F.stride, dataType: F.mpsType)
		pipeline = try device.makeComputePipelineState(function: function)
		inputs = [x, a]
		offsets = Array<Int>(repeating: 0, count: inputs.count)
		range = 1..<(1+inputs.count)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension FMAVVS: Sym {
	var xtype: XType.Type {
		return F.self
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
		let buffers: [MTLBuffer] = try inputs.map { try $0.eval(commandBuffer: commandBuffer) }
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
		encoder.setBuffer(matrix.data, offset: 0, index: 0)
		encoder.setBuffers(buffers, offsets: offsets, range: range)
		encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
		return matrix.data
	}
}
struct FMAVVV {
	let xtype: XType.Type
	let descriptor: MPSMatrixDescriptor
	let pipeline: MTLComputePipelineState
	let inputs: [Sym]
	let offsets: [Int]
	let range: Range<Int>
	let threads: MTLSize
	let groups: MTLSize
	init(x: Sym, a: Sym, b: Sym) throws {
		
		assert( x.device === a.device )
		assert( x.device === b.device )
		assert( ( x.rows, x.columns ) == ( a.rows, a.columns ) )
		assert( ( x.rows, x.columns ) == ( b.rows, b.columns ) )
		assert( x.xtype is XFloat.Type )
		assert({switch ($0, $1, $2){
		case is (Float16.Type, Float16.Type, Float16.Type),
			 is (Float32.Type, Float32.Type, Float32.Type):
			return true
		default:
			return false
		}}(x.xtype, a.xtype, b.xtype))
		
		let device: MTLDevice = x.device
		let rows: Int = x.rows
		let columns: Int = x.columns
		let length: Int = rows * columns
		let library: MTLLibrary = try device.makeDefaultLibrary(bundle: Bundle(for: Context.self))
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues()
			.binding(value: uint(length), for: "count")
		let function: MTLFunction = try library.makeFunction(name: "FMAVVV_\(x.xtype.description)", constantValues: constantValues)

		xtype = x.xtype
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * xtype.stride, dataType: xtype.mpsType)
		pipeline = try device.makeComputePipelineState(function: function)
		inputs = [x, a, b]
		offsets = Array<Int>(repeating: 0, count: inputs.count)
		range = 1..<(1+inputs.count)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension FMAVVV: Sym {
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
		let buffers: [MTLBuffer] = try inputs.map { try $0.eval(commandBuffer: commandBuffer) }
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
		assert( buffers.count == range.count )
		assert( buffers.count == offsets.count )
		encoder.setBuffer(matrix.data, offset: 0, index: 0)
		encoder.setBuffers(buffers, offsets: offsets, range: range)
		encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
		return matrix.data
	}
}


public func fma<F>(_ x: Sym, _ a: F, _ b: F) throws -> Sym where F : XType, F : XFloat {
	return try FMAVSS(x: x, a: a, b: b)
}
public func fma<F>(_ x: Sym, _ a: Sym, _ b: F) throws -> Sym where F : XType, F : XFloat {
	return try FMAVVS(x: x, a: a, b: b)
}
public func fma<F>(_ x: Sym, _ a: F, _ b: Sym) throws -> Sym where F : XType, F : XFloat {
	return try FMAVSV(x: x, a: a, b: b)
}
public func fma<F>(_ x: F, _ a: Sym, _ b: Sym) throws -> Sym where F : XType, F : XFloat {
	return try FMAVSV(x: a, a: x, b: b)
}
public func fma(_ x: Sym, _ a: Sym, _ b: Sym) throws -> Sym {
	return try FMAVVV(x: x, a: a, b: b)
}
