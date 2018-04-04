//
//  Context.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import Accelerate
import MetalPerformanceShaders
public class Context {
	let device: MTLDevice
	let queue: MTLCommandQueue
	init(device D: MTLDevice) throws {
		guard let Q: MTLCommandQueue = D.makeCommandQueue() else {
			throw ErrorCases.any
		}
		device = D
		queue = Q
	}
}
extension Context {
	func makeCommandBuffer(caller: String = #function) throws -> MTLCommandBuffer {
		return try queue.makeCommandBuffer(caller: caller)
	}
}
extension MTLCommandQueue {
	func makeCommandBuffer(caller: String = #function) throws -> MTLCommandBuffer {
		guard let commandBuffer: MTLCommandBuffer = makeCommandBuffer() else {
			throw ErrorCases.any
		}
		commandBuffer.label = caller
		return commandBuffer
	}
}
extension MTLCommandBuffer {
	func makeBlitCommandEncoder(caller: String = #function) throws -> MTLBlitCommandEncoder {
		guard let encoder: MTLBlitCommandEncoder = makeBlitCommandEncoder() else {
			throw ErrorCases.any
		}
		encoder.label = caller
		return encoder
	}
	func makeComputeCommandEncoder(caller: String = #function) throws -> MTLComputeCommandEncoder {
		guard let encoder: MTLComputeCommandEncoder = makeComputeCommandEncoder() else {
			throw ErrorCases.any
		}
		encoder.label = caller
		return encoder
	}
}
extension Context {
	func eval(block: @escaping()->Void) throws {
		let runloop: RunLoop = .current
		guard let command: MTLCommandBuffer = queue.makeCommandBuffer() else {
			throw ErrorCases.any
		}
		command.addCompletedHandler { (_) in
			runloop.perform(block)
		}
		command.commit()
	}
	func eval<T>(symbol x: Symbol) throws -> Buffer<T> where T : MPSType {
		guard let commandBuffer: MTLCommandBuffer = queue.makeCommandBuffer() else {
			throw ErrorCases.any
		}
		let count: Int = x.count
		let rows: Int = x.rows
		let columns: Int = x.columns
		commandBuffer.commit()
		return try makeBuffer(length: 0)
	}
	func eval(symbol: Symbol) throws {
		guard let commandBuffer: MTLCommandBuffer = queue.makeCommandBuffer() else {
			throw ErrorCases.any
		}
		commandBuffer.commit()
	}
	func join() throws {
		guard let commandBuffer: MTLCommandBuffer = queue.makeCommandBuffer() else {
			throw ErrorCases.any
		}
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
	}
}

