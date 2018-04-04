//
//  Map.swift
//  C3
//
//  Created by Kota Nakano on 4/3/18.
//
import Accelerate
import MetalPerformanceShaders
private var uniq: String {
	return (["id" as Substring] + UUID().uuidString.split(separator: "-")).joined()
}
private let __kernel__: String = "map"
private let __name__: String = uniq
private let __type__: String = uniq
private let __index__: String = "__index__"
private let __count__: String = "__count__"
private let __fetch__: String = uniq
private let __store__: String = uniq
private let __argument__: String = uniq
private let __template__: String = """
using namespace metal;
constant uint \(__count__) [[ function_constant(0) ]];
kernel void \(__kernel__)(
	device \(__type__) * const \(__name__) [[ buffer(0) ]],
	\(__argument__),
	uint const \(__index__) [[ thread_position_in_grid ]]) {
	if ( \(__index__) < \(__count__) ) {
		\(__fetch__);
		\(__store__);
	}
}
"""
class Map {
	let pipeline: MTLComputePipelineState
	let count: Int
	let rows: Int
	let columns: Int
	let input: [Symbol]
	let groups: MTLSize
	let threads: MTLSize
	let offsets: [Int]
	let range: Range<Int>
	let type: MPSType.Type
	var evaluated: (MTLCommandBuffer, MPSTemporaryMatrix)?
	init(type T: MPSType.Type, lambda: String, source X: [String: Symbol]) throws {
		guard let (_, primary): (String, Symbol) = X.first else {
			throw ErrorCases.any
		}
		let source: [(String, Symbol)] = try X.map {
			guard
				primary.count == $1.count,
				primary.rows == $1.rows,
				primary.columns == $1.columns,
				primary.device === $1.device else { throw ErrorCases.any }
			return ($0, $1)
		}
		let device: MTLDevice = primary.device
		type = T
		count = primary.count
		rows = primary.rows
		columns = primary.columns
		let length: Int = count * rows * columns
		let argument: [(String, String)] = source.enumerated().map {
			let temp: String = uniq
			let b: String = "thread \($1.1.type.description) const \($1.0) = \(temp) [ \(__index__) ]"
			let a: String = "device \($1.1.type.description) const * const \(temp) [[ buffer(\( $0 + 1 )) ]]"
			return (a, b)
		}
		let store: String = "\(__name__) [ \(__index__) ] = \(lambda)"
		let code: String = __template__
			.replacingOccurrences(of: __type__, with: T.description)
			.replacingOccurrences(of: __argument__, with: argument.map { $0.0 }.joined(separator: ",\r\n\t"))
			.replacingOccurrences(of: __fetch__, with: argument.map { $0.1 }.joined(separator: ";\r\n\t\t"))
			.replacingOccurrences(of: __store__, with: store)
		let library: MTLLibrary = try device.makeLibrary(source: code, options: nil)
		let constantValues: MTLFunctionConstantValues = MTLFunctionConstantValues().binding(value: uint(length), for: __count__)
		let function: MTLFunction = try library.makeFunction(name: __kernel__, constantValues: constantValues)
		input = source.map { $1 }
		pipeline = try device.makeComputePipelineState(function: function)
		threads = MTLSize(width: pipeline.threadExecutionWidth, height: 1, depth: 1)
		groups = MTLSize(width: ( length - 1 ) / threads.width + 1, height: 1, depth: 1)
		offsets = [Int](repeating: 0, count: source.count)
		range = 1..<source.count + 1
	}
}
extension Map: Symbol {
	func eval(commandBuffer: MTLCommandBuffer) throws -> MPSArray {
		if let (previous, matrix): (MTLCommandBuffer, MPSTemporaryMatrix) = evaluated, previous === commandBuffer {
			return matrix
		}
		let buffers: [MTLBuffer] = try input.map { try $0.eval(commandBuffer: commandBuffer).data }
		guard let encoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else {
			throw ErrorCases.any
		}
		let rowBytes: Int = columns * type.stride
		let matrixBytes: Int = rows * rowBytes
		let shape: MPSMatrixDescriptor = MPSMatrixDescriptor(rows: rows, columns: columns, matrices: count, rowBytes: rowBytes, matrixBytes: matrixBytes, dataType: type.mpsType)
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: shape)
		defer {
			evaluated = (commandBuffer, matrix)
		}
		encoder.setComputePipelineState(pipeline)
		encoder.setBuffer(matrix.data, offset: 0, index: 0)
		encoder.setBuffers(buffers, offsets: offsets, range: range)
		encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
		encoder.endEncoding()
		return matrix
	}
	var device: MTLDevice {
		return pipeline.device
	}
	var transpose: Bool {
		return false
	}
}
public func map(type: MPSType.Type, lambda: String, source: [String: Symbol]) throws -> Symbol {
	return try Map(type: type, lambda: lambda, source: source)
}
