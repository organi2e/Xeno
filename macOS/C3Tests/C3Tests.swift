//
//  C3Tests.swift
//  C3Tests
//
//  Created by Kota Nakano on 3/30/18.
//

import XCTest
@testable import C3
extension String: Error { }
class C3Tests: XCTestCase {
	func testMap() {
		do {
			guard let device: MTLDevice = MTLCreateSystemDefaultDevice() else { throw "no device" }
			let context: Context = try Context(device: device)
			var x: Buf<Float32> = try context.makeMatrix(rows: 4, columns: 4)
			let y: Sym = try map(type: Float32.self, lambda: "log(x+2)*log(x+2)", source: ["x": x])
			let z: Buf<UInt16> = try context.makeMatrix(rows: 4, columns: 4)
			let t: Task = try copying(from: y, to: z)
			try context.eval {
				x[0] = 65535
			}
			try context.eval(task: t)
			try context.eval {
				print("a", z[0], z[1], z[2])
			}
			try context.join()
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
}

