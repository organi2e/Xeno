//
//  Uniform.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import Accelerate
import MetalPerformanceShaders
struct IntegerUniform<X> where X : XType {
	let rows: Int
	let columns: Int
	let buffer: MTLBuffer
	let queue: DispatchQueue
	let group: DispatchGroup
	init(device: MTLDevice, rows r: Int, columns c: Int) throws {
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
extension Context {
	public func makeUniform<X>(type: X.Type, rows: Int, columns: Int) throws -> Sym where X : XType{
		switch type {
		case is Float16.Type:
			let u: Sym = try IntegerUniform<UInt8>(device: device, rows: rows, columns: columns)
			return try map(type: type, lambda: "( u + 0.5 ) / 256.0", source: ["u": u])
		case is Float32.Type:
			let u: Sym = try IntegerUniform<UInt16>(device: device, rows: rows, columns: columns)
			return try map(type: type, lambda: "( u + 0.5 ) / 65536.0", source: ["u": u])
		default:
			return try IntegerUniform<X>(device: device, rows: rows, columns: columns)
		}
	}
}
