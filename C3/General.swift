//
//  math.swift
//  C3
//
//  Created by Kota Nakano on 4/6/18.
//
private let error: Error = ErrorCases.any
import MetalPerformanceShaders
struct General {
	let xtype: XType.Type
	let descriptor: MPSMatrixDescriptor
	let pipeline: MTLComputePipelineState
	let inputs: [Sym]
	let offsets: [Int]
	let range: Range<Int>
	let threads: MTLSize
	let groups: MTLSize
	init(name: String, source S: [Sym]) throws {
		guard let primary: Sym = S.first else {
			throw ErrorCases.any
		}
		let device: MTLDevice = primary.device
		let rows: Int = primary.rows
		let columns: Int = primary.columns
		assert( primary.xtype is XFloat.Type )
		assert( S.reduce(true) { $0 && $1.device === device } )
		assert( S.reduce(true) { $0 && $1.xtype == primary.xtype } )
		assert( S.reduce(true) { $0 && ($1.rows, $1.columns) == (rows, columns) } )
		
		let length: Int = primary.length
		let library: MTLLibrary = try device.makeDefaultLibrary(bundle: Bundle(for: Context.self))
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues().binding(value: uint(length), for: "count")
		xtype = primary.xtype
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * xtype.stride, dataType: xtype.mpsType)
		pipeline = try device.makeComputePipelineState(function: library.makeFunction(name: "\(name)_\(xtype.description)", constantValues: constantValues))
		inputs = S
		offsets = Array<Int>(repeating: 0, count: inputs.count)
		range = 1..<(1+inputs.count)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: (length-1)/threads.width+1, height: 1, depth: 1)
	}
}
extension General: Sym {
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

public func fract(_ x: Sym) throws -> Sym { return try General(name: "fract", source: [x]) }
public func round(_ x: Sym) throws -> Sym { return try General(name: "round", source: [x]) }
public func floor(_ x: Sym) throws -> Sym { return try General(name: "floor", source: [x]) }
public func ceil(_ x: Sym) throws -> Sym { return try General(name: "ceil", source: [x]) }

public func log(_ x: Sym) throws -> Sym { return try General(name: "log", source: [x]) }
public func exp(_ x: Sym) throws -> Sym { return try General(name: "exp", source: [x]) }

public func cos(_ x: Sym) throws -> Sym { return try General(name: "cos", source: [x]) }
public func sin(_ x: Sym) throws -> Sym { return try General(name: "sin", source: [x]) }
public func tan(_ x: Sym) throws -> Sym { return try General(name: "tan", source: [x]) }

public func cosh(_ x: Sym) throws -> Sym { return try General(name: "cosh", source: [x]) }
public func sinh(_ x: Sym) throws -> Sym { return try General(name: "sinh", source: [x]) }
public func tanh(_ x: Sym) throws -> Sym { return try General(name: "tanh", source: [x]) }

public func acos(_ x: Sym) throws -> Sym { return try General(name: "acos", source: [x]) }
public func asin(_ x: Sym) throws -> Sym { return try General(name: "asin", source: [x]) }
public func atan(_ x: Sym) throws -> Sym { return try General(name: "atan", source: [x]) }

public func acosh(_ x: Sym) throws -> Sym { return try General(name: "acosh", source: [x]) }
public func asinh(_ x: Sym) throws -> Sym { return try General(name: "asinh", source: [x]) }
public func atanh(_ x: Sym) throws -> Sym { return try General(name: "atanh", source: [x]) }

public func cospi(_ x: Sym) throws -> Sym { return try General(name: "cospi", source: [x]) }
public func sinpi(_ x: Sym) throws -> Sym { return try General(name: "sinpi", source: [x]) }
public func tanpi(_ x: Sym) throws -> Sym { return try General(name: "tanpi", source: [x]) }

public func sqrt(_ x: Sym) throws -> Sym { return try General(name: "sqrt", source: [x]) }
public func rsqrt(_ x: Sym) throws -> Sym { return try General(name: "rsqrt", source: [x]) }

public func erf(_ x: Sym) throws -> Sym { return try General(name: "erf", source: [x]) }
public func erfinv(_ x: Sym) throws -> Sym { return try General(name: "erfinv", source: [x]) }

public func fmod(_ x: Sym, _ y: Sym) throws -> Sym {
	return try General(name: "fmod", source: [x, y])
}
public func pow(_ x: Sym, _ y: Sym) throws -> Sym {
	return try General(name: "pow", source: [x, y])
}
public func powr(_ x: Sym, _ y: Sym) throws -> Sym {
	return try General(name: "powr", source: [x, y])
}

/*
public func sin(_ x: Sym) throws -> Sym {
	switch x.xtype {
	case is Float16.Type, is Float32.Type:
		return try map(type: x.xtype, lambda: "sin(x)", source: ["x": x])
	default:
		assertionFailure()
		throw error
	}
}
public func cos(_ x: Sym) throws -> Sym {
	switch x.xtype {
	case is Float16.Type, is Float32.Type:
		return try map(type: x.xtype, lambda: "cos(x)", source: ["x": x])
	default:
		assertionFailure()
		throw error
	}
}
public func tan(_ x: Sym) throws -> Sym {
	switch x.xtype {
	case is Float16.Type, is Float32.Type:
		return try map(type: x.xtype, lambda: "tan(x)", source: ["x": x])
	default:
		assertionFailure()
		throw ErrorCases.any
	}
}
public func sinh(_ x: Sym) throws -> Sym {
	switch x.xtype {
	case is Float16.Type, is Float32.Type:
		return try map(type: x.xtype, lambda: "sinh(x)", source: ["x": x])
	default:
		assertionFailure()
		throw error
	}
}
public func cosh(_ x: Sym) throws -> Sym {
	switch x.xtype {
	case is Float16.Type, is Float32.Type:
		return try map(type: x.xtype, lambda: "cosh(x)", source: ["x": x])
	default:
		assertionFailure()
		throw error
	}
}
public func tanh(_ x: Sym) throws -> Sym {
	switch x.xtype {
	case is Float16.Type, is Float32.Type:
		return try map(type: x.xtype, lambda: "tanh(x)", source: ["x": x])
	default:
		assertionFailure()
		throw error
	}
}
public func fma(_ a: Sym, _ b: Sym, _ c: Sym) throws -> Sym {
	switch (a.xtype, b.xtype, c.xtype) {
	case is (Float16.Type, Float16.Type, Float16.Type):
		return try map(type: Float16.self, lambda: "fma(a, b, c)", source: ["a": a, "b": b, "c": c])
	case is (Float32.Type, Float32.Type, Float32.Type):
		return try map(type: Float32.self, lambda: "fma(a, b, c)", source: ["a": a, "b": b, "c": c])
	default:
		assertionFailure()
		throw error
	}
}
*/
