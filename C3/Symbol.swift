//
//  Symbol.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import Accelerate
import MetalPerformanceShaders
public protocol Sym {
	var rows: Int { get }
	var columns: Int { get }
	var transpose: Bool { get }
	var type: MPSType.Type { get }
	var device: MTLDevice { get }
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer
}
public protocol Symbol {
	var count: Int { get }
	var rows: Int { get }
	var columns: Int { get }
	var transpose: Bool { get }
	var type: MPSType.Type { get }
	var device: MTLDevice { get }
	func eval(commandBuffer: MTLCommandBuffer) throws -> MPSArray
}
extension Symbol {
	public var shape: MPSMatrixDescriptor {
		let rowBytes: Int = columns * type.stride
		let matrixBytes: Int = rows * rowBytes
		return MPSMatrixDescriptor(rows: rows, columns: columns, matrices: count, rowBytes: rowBytes, matrixBytes: matrixBytes, dataType: type.mpsType)
	}
}