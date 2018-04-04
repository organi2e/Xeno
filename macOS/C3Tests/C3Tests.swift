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
			var x: Buffer<Float> = try context.makeBuffer(length: 64)
			try context.eval {
				x[0] = 3
			}
			let y: Symbol = try map(type: Float32.self, lambda: "x * x", source: ["x": x])
			let z: Buffer<Float> = try context.eval(symbol: y)
			/*
			let y: Symbol = try square(x)
			let z: Buffer<Float> = try context.eval(symbol: y)
			try context.eval {
				print("val", z[0])
			}
			try context.join()
			*/
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
	func test() {
		/*
		let x: Buffer = try context.makeBuffer<Float>(rows: 784, columns: 10)
		let wu: Buffer = try context.makeBuffer<Float>(rows: 512, columns: 784)
		let ws: Buffer = try context.makeBuffer<Float>(rows: 512, columns: 784)
		let bu: Buffer = try context.makeBuffer<Float>(rows: 512, columns: 1)
		let bs: Buffer = try context.makeBuffer<Float>(rows: 512, columns: 1)
		*/
		/*
		let vu: Symbol = sum(matrices: [matmul(wu, x)], columnBias: bu)
		let vu: Symbol = try matmul(wu, x) + bu
		let vs: Symbol = try sqrt(matmul(ws * ws, x * x) + bs * bs)
		let N: Distribution = try Normal<Float32>(u: vu, s: vs)
		let U: Distribution = try Uniform<Float32>(0, 1)
		let p: Symbol = N.cdf
		let r: Random = N.random
		let v: Sample = N.sample
		let u: Symbol = context.Buffer(type: float32, 784, 10)
		let fn: Symbol = map<Float32>('v>0', ['v': v])
		let fu: Symbol = map<Float32>('p>u', ['p': p, 'u': u])
		try context.eval {
		x.store(la)
		y.store(la)
		}
		let s = try context.eval(fn)
		let x: la_object = s.la
		s.ready
		
		*/
	}
}

