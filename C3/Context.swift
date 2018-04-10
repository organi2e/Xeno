//
//  Context.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import Accelerate
import MetalPerformanceShaders
public class Context {
	let runloop: RunLoop
	let bundle: Bundle
	let device: MTLDevice
	let library: MTLLibrary
	let queue: MTLCommandQueue
	init(device D: MTLDevice) throws {
		runloop = .current
		bundle = Bundle(for: Context.self)
		device = D
		queue = try device.makeCommandQueue()
		library = try device.makeDefaultLibrary(bundle: bundle)
	}
}
extension Context {
	func makeCommandBuffer(caller: String = #function) throws -> MTLCommandBuffer {
		return try queue.makeCommandBuffer(caller: caller)
	}
}
extension MTLDevice {
	func makeCommandQueue(caller: String = #function) throws -> MTLCommandQueue {
		guard let queue: MTLCommandQueue = makeCommandQueue() else {
			throw ErrorCases.any
		}
		queue.label = caller
		return queue
	}
	func makeBuffer(length: Int, options: MTLResourceOptions, caller: String = #function) throws -> MTLBuffer {
		guard let buffer: MTLBuffer = makeBuffer(length: length, options: options) else {
			throw ErrorCases.any
		}
		buffer.label = caller
		return buffer
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
	func eval<X>(symbol: Sym) throws -> Buf<X> where X : XType {
		let matrix: Buf<X> = try makeMatrix(rows: symbol.rows, columns: symbol.columns)
		let commandBuffer: MTLCommandBuffer = try queue.makeCommandBuffer()
		try store(to: matrix, from: symbol).eval(commandBuffer: commandBuffer)
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
		return matrix
	}
	func eval(block: @escaping()->Void) throws {
		let commandBuffer: MTLCommandBuffer = try queue.makeCommandBuffer()
		commandBuffer.addCompletedHandler { (_) in block() }
		commandBuffer.commit()
	}
	func eval(task: Task) throws {
		let commandBuffer: MTLCommandBuffer = try queue.makeCommandBuffer()
		try task.eval(commandBuffer: commandBuffer)
		commandBuffer.commit()
	}
	func join() throws {
		 let commandBuffer: MTLCommandBuffer = try queue.makeCommandBuffer()
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
	}
}

