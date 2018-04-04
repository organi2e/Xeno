//
//  Command.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import Accelerate
import Metal
public protocol Command {
	func success(block: @escaping()->Void) -> Command
	func commit() -> Command
	func join()
}
struct C3Command {
	let imp: MTLCommandBuffer
}
extension C3Command: Command {
	func success(block: @escaping()->Void) -> Command {
		var x: MTLCommandBuffer?
		imp.addCompletedHandler { _ in
			block()
		}
		return self
	}
	func commit() -> Command {
		imp.commit()
		return self
	}
	func join() {
		imp.waitUntilCompleted()
	}
}
