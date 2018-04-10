//
//  Cache.swift
//  C3
//
//  Created by Kota Nakano on 4/5/18.
//
import Metal
class Cache {
	let x: Sym
	var last: (MTLCommandBuffer, MTLBuffer)?
	init(input: Sym) {
		x = input
	}
}
extension Cache: Sym {
	var xtype: XType.Type {
		return x.xtype
	}
	var rows: Int {
		return x.rows
	}
	var columns: Int {
		return x.columns
	}
	var device: MTLDevice {
		return x.device
	}
	func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		if let (command, buffer): (MTLCommandBuffer, MTLBuffer) = last, command === commandBuffer {
			return buffer
		} else {
			let buffer: MTLBuffer = try x.eval(commandBuffer: commandBuffer)
			last = (commandBuffer, buffer)
			return buffer
		}
	}
}
public func cache(_ input: Sym) -> Sym {
	return Cache(input: input)
}
