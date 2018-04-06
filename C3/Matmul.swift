//
//  Matmul.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import Accelerate
import MetalPerformanceShaders
class vDOT {
	private static let __atype__: String = "__atype__"
	private static let __btype__: String = "__btype__"
	private static let __ctype__: String = "__ctype__"
	private static let __count__: String = "__count__"
	private static let __index__: String = "__index__"
	private static let __width__: String = "__width__"
	private static let __share__: String = "__share__"
	private static let __kernel__: String = "__kernel__"
	private static let __template__: String = """
#include <metal_stdlib>
using namespace metal;
constant uint const \(__count__) [[ function_constant(0) ]];
kernel void \(__kernel__)(
	device \(__ctype__) * const C [[ buffer(0) ]],
	device \(__atype__) const * const A [[ buffer(1) ]],
	device \(__btype__) const * const B [[ buffer(2) ]],
	threadgroup \(__ctype__) * const \(__share__) [[ threadgroup(0) ]],
	uint const \(__index__) [[ thread_position_in_grid ]],
	uint const \(__width__) [[ threads_per_grid ]]) {
	
	thread \(__ctype__) v = 0;
	for ( thread uint n = \(__index__), N = \(__count__) ; n < N ; n += \(__width__) )
		v += A[n] * B[n];
	
	uint const a = \(__index__);
	uint b = \(__width__);
	
	threadgroup \(__ctype__) * s = \(__share__) + a;
	* s = v;
	
	while ( b >>= 1 ) {
		threadgroup_barrier(mem_flags::mem_threadgroup);
		if ( a < b ) * s += * ( s + b );
	}
	if ( !a ) * C = * s;
}
"""
	let xtype: XType.Type
	let pipeline: MTLComputePipelineState
	let descriptor: MPSMatrixDescriptor
	let cacheSize: Int
	let groups: MTLSize
	let threads: MTLSize
	let sA: Sym
	let sB: Sym
	init(type: XType.Type, A: Sym, B: Sym) throws {
		assert( A.device === B.device )
		assert( A.rows == 1 )
		assert( B.columns == 1 )
		assert( A.columns == B.rows )
		let K: vDOT.Type = vDOT.self
		let source: String = K.__template__
			.replacingOccurrences(of: K.__atype__, with: A.xtype.description)
			.replacingOccurrences(of: K.__btype__, with: B.xtype.description)
			.replacingOccurrences(of: K.__ctype__, with: type.description)
		let length: Int = min(A.length, B.length)
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues().binding(value: uint(length), for: K.__count__)
		let library: MTLLibrary = try A.device.makeLibrary(source: source, options: nil)
		let function: MTLFunction = try library.makeFunction(name: K.__kernel__, constantValues: constantValues)
		xtype = type
		sA = A
		sB = B
		pipeline = try A.device.makeComputePipelineState(function: function)
		descriptor = MPSMatrixDescriptor(rows: 1, columns: 1, rowBytes: type.size, dataType: type.mpsType)
		cacheSize = pipeline.threadExecutionWidth * type.stride
		groups = MTLSize(width: 1, height: 1, depth: 1)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
	}
}
extension vDOT : Sym {
	var device: MTLDevice {
		return pipeline.device
	}
	var rows: Int {
		return 1
	}
	var columns: Int {
		return 1
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		assert( commandBuffer.device === pipeline.device )
		let A: MTLBuffer = try sA.eval(commandBuffer: commandBuffer)
		let B: MTLBuffer = try sB.eval(commandBuffer: commandBuffer)
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		let encoder: MTLComputeCommandEncoder = try commandBuffer.makeComputeCommandEncoder()
		encoder.setComputePipelineState(pipeline)
		encoder.setBuffer(matrix.data, offset: 0, index: 0)
		encoder.setBuffer(A, offset: 0, index: 1)
		encoder.setBuffer(B, offset: 0, index: 2)
		encoder.setThreadgroupMemoryLength(cacheSize, index: 0)
		encoder.dispatchThreads(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
		return matrix.data
	}
}

class GEMM {
	let xtype: XType.Type
	let descriptor: MPSMatrixDescriptor
	let kernel: MPSMatrixMultiplication
	let sA: (Sym, MPSMatrixDescriptor)
	let sB: (Sym, MPSMatrixDescriptor)
	var last: (MTLCommandBuffer, MTLBuffer)?
	init(type: XType.Type, A: Sym, B: Sym) {
		assert( A.device === B.device )
		assert( A.rows != 1 )
		assert( B.columns != 1 )
		assert( A.columns == B.rows )
		assert( A.xtype == type )
		assert( B.xtype == type )
		xtype = type
		descriptor = MPSMatrixDescriptor(rows: A.rows, columns: B.columns, rowBytes: B.columns * xtype.stride, dataType: xtype.mpsType)
		kernel = MPSMatrixMultiplication(device: A.device, resultRows: descriptor.rows, resultColumns: descriptor.columns, interiorColumns: min(A.columns, B.rows))
		sA = (A, MPSMatrixDescriptor(rows: A.rows, columns: A.columns, rowBytes: A.columns * A.xtype.stride, dataType: A.xtype.mpsType))
		sB = (B, MPSMatrixDescriptor(rows: B.rows, columns: B.columns, rowBytes: B.columns * B.xtype.stride, dataType: B.xtype.mpsType))
	}
}
extension GEMM : Sym {
	var rows: Int {
		return descriptor.rows
	}
	var columns: Int {
		return descriptor.columns
	}
	var device: MTLDevice {
		return kernel.device
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		if let (command, buffer): (MTLCommandBuffer, MTLBuffer) = last, command === commandBuffer {
			return buffer
		} else {
			assert(commandBuffer.device === kernel.device)
			let c: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
			try kernel.encode(commandBuffer: commandBuffer,
							  leftMatrix: MPSMatrix(buffer: sA.0.eval(commandBuffer: commandBuffer), descriptor: sA.1),
							  rightMatrix: MPSMatrix(buffer: sB.0.eval(commandBuffer: commandBuffer), descriptor: sB.1),
							  resultMatrix: c)
			last = (commandBuffer, c.data)
			return c.data
		}
	}
}
class GEMV {
	let xtype: XType.Type
	let descriptor: MPSVectorDescriptor
	let kernel: MPSMatrixVectorMultiplication
	let rows: Int
	let columns: Int
	let sA: (Sym, MPSMatrixDescriptor)
	let sx: (Sym, MPSVectorDescriptor)
	let y: MPSVector//MPSTemporaryVector cannot work for mpsmatrixvectormultiplication by causing assertion
	var last: (MTLCommandBuffer, MTLBuffer)?
	init(type: XType.Type, A : Sym, x: Sym) throws {
		assert( A.device === x.device )
		assert( x.columns == 1 )
		assert( A.columns == x.rows )
		(rows, columns) = (A.rows, x.columns)
		xtype = type
		descriptor = MPSVectorDescriptor(length: A.rows, dataType: xtype.mpsType)
		kernel = MPSMatrixVectorMultiplication(device: A.device, transpose: .F, rows: A.rows, columns: A.columns, alpha: 1, beta: 0)
		sA = (A, MPSMatrixDescriptor(rows: A.rows, columns: A.columns, rowBytes: A.columns * A.xtype.stride, dataType: A.xtype.mpsType))
		sx = (x, MPSVectorDescriptor(length: x.rows, dataType: x.xtype.mpsType))
		y = try MPSVector(buffer: A.device.makeBuffer(length: descriptor.length * xtype.stride, options: .storageModePrivate), descriptor: descriptor)
	}
	init(type: XType.Type, x: Sym, A: Sym) throws {
		assert( A.device === x.device )
		assert( x.rows == 1 )
		assert( A.rows == x.columns )
		(rows, columns) = (x.rows, A.columns)
		xtype = type
		descriptor = MPSVectorDescriptor(length: A.columns, dataType: xtype.mpsType)
		kernel = MPSMatrixVectorMultiplication(device: A.device, transpose: .T, rows: A.columns, columns: A.rows, alpha: 1, beta: 0)
		sA = (A, MPSMatrixDescriptor(rows: A.rows, columns: A.columns, rowBytes: A.columns * A.xtype.stride, dataType: A.xtype.mpsType))
		sx = (x, MPSVectorDescriptor(length: x.columns, dataType: x.xtype.mpsType))
		y = try MPSVector(buffer: A.device.makeBuffer(length: descriptor.length * xtype.stride, options: .storageModePrivate), descriptor: descriptor)
	}
}
extension GEMV : Sym {
	var device: MTLDevice {
		return kernel.device
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		if let (command, buffer): (MTLCommandBuffer, MTLBuffer) = last, command === commandBuffer {
			return buffer
		} else {
			assert(commandBuffer.device === kernel.device)
//			let y: MPSTemporaryVector = MPSTemporaryVector(commandBuffer: commandBuffer, descriptor: descriptor)
			try kernel.encode(commandBuffer: commandBuffer,
							  inputMatrix: MPSMatrix(buffer: sA.0.eval(commandBuffer: commandBuffer), descriptor: sA.1),
							  inputVector: MPSVector(buffer: sx.0.eval(commandBuffer: commandBuffer), descriptor: sx.1),
							  resultVector: y)
			last = (commandBuffer, y.data)
			return y.data
		}
	}
}
public func matmul(type: XType.Type, _ A: Sym, _ B: Sym) throws -> Sym {
	assert( A.device === B.device )
	assert( A.columns == B.rows )
	switch (type == A.xtype, type == B.xtype, A.rows, B.columns) {
	case (_, _, 1, 1):
		return try vDOT(type: type, A: A, B: B)
	case (true, true, 1, _):
		return try GEMV(type: type, x: A, A: B)
	case (true, true, _, 1):
		return try GEMV(type: type, A: A, x: B)
	case (true, true, _, _):
		return GEMM(type: type, A: A, B: B)
	case (_, _, 1, _): assertionFailure("not implemented \(#function) for \(A.xtype, B.xtype, A.rows, B.columns)")
	case (_, _, _, 1): assertionFailure("not implemented \(#function) for \(A.xtype, B.xtype, A.rows, B.columns)")
	case (_, _, _, _): assertionFailure("not implemented \(#function) for \(A.xtype, B.xtype, A.rows, B.columns)")
	}
	throw ErrorCases.any
}
