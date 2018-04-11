//
//  Expand.swift
//  C3
//
//  Created by Kota Nakano on 4/11/18.
//
import MetalPerformanceShaders
struct Expansion {
	let descriptor: MPSMatrixDescriptor
	let task: MPSMatrixCopy
	let input: Sym
	let offsets: MPSMatrixCopyOffsets
	init(source s: Sym, l: Int, t: Int, b: Int, r: Int) throws {
		let device: MTLDevice = s.device
		let rows: Int = t + s.rows + b
		let columns: Int = l + s.columns + r
		descriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * s.xtype.stride, dataType: s.xtype.mpsType)
		task = MPSMatrixCopy(device: device, copyRows: s.rows, copyColumns: s.columns, sourcesAreTransposed: .F, destinationsAreTransposed: .F)
		input = s
		offsets = MPSMatrixCopyOffsets(sourceRowOffset: 0, sourceColumnOffset: 0, destinationRowOffset: UInt32(t), destinationColumnOffset: UInt32(l))
	}
}
extension Expansion {
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		let buffer: MTLBuffer = try input.eval(commandBuffer: commandBuffer)
		let source: MPSMatrix = MPSMatrix(buffer: buffer, descriptor: descriptor)
		
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		let encoder: MTLBlitCommandEncoder = try commandBuffer.makeBlitCommandEncoder()
		encoder.fill(buffer: matrix.data, range: 0..<matrix.data.length, value: 0)
		encoder.endEncoding()
		
		let copy: MPSMatrixCopyDescriptor = MPSMatrixCopyDescriptor(sourceMatrix: source, destinationMatrix: matrix, offsets: offsets)
		task.encode(commandBuffer: commandBuffer, copyDescriptor: copy)
		return matrix.data
	}
}
