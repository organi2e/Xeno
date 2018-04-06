//
//  C3Tests.swift
//  C3Tests
//
//  Created by Kota Nakano on 3/30/18.
//
import Accelerate
import XCTest
@testable import C3
extension String: Error { }
class C3Tests: XCTestCase {
	func eval(block: (Context)throws->Void) {
		do {
			guard let device: MTLDevice = MTLCreateSystemDefaultDevice() else { throw "no device" }
			let context: Context = try Context(device: device)
			try block(context)
			try context.join()
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
	func testUniform() {
		eval { context in 
			let rows: Int = 1024
			let columns: Int = 1024
			let a: Sym = try context.makeUniform(type: Float32.self, rows: rows, columns: columns)
			let b: Buf<Float32> = try context.eval(symbol: a)
			let c: la_object_t = b.fetch()
			var x: la_object_t = c
			print(x.array.reduce(0, +) / Float(rows*columns))
			x = la_elementwise_product(x, c)
			print(x.array.reduce(0, +) / Float(rows*columns))
			x = la_elementwise_product(x, c)
			print(x.array.reduce(0, +) / Float(rows*columns))
			x = la_elementwise_product(x, c)
			print(x.array.reduce(0, +) / Float(rows*columns))
			x = la_elementwise_product(x, c)
			
			
		}
	}
	func testDot() {
		eval { context in
			let N: Int = 64
			let a: Buf<Float32> = try context.makeMatrix(rows: 1, columns: 64)
			let b: Buf<Float32> = try context.makeMatrix(rows: 64, columns: 1)
			(0..<N).forEach {
				a[$0] = Float32($0)
				b[$0] = Float32($0)
			}
			let c: Buf<Float32> = try context.eval(symbol: matmul(type: Float32.self, a, b))
			print(c.array)
		}
	}
	func testErf() {
		eval { context in
			let N: Int = 64
			let u: Sym = try context.makeUniform(type: Float32.self, rows: 1, columns: N)
			let a: Buf<Float32> = try context.makeMatrix(rows: 1, columns: N)
			try context.eval(task: store(to: a, from: u))
			let b: Sym = try erfinv(a)
			let c: Buf<Float32> = try context.eval(symbol: b)
			try context.eval {
				print(a.array)
				print(c.array.map(erff))
			}
		}
	}
	/*
	func testMap() {
		do {
			guard let device: MTLDevice = MTLCreateSystemDefaultDevice() else { throw "no device" }
			let context: Context = try Context(device: device)
			var a: Buf<Float32> = try context.makeMatrix(rows: 1, columns: 3)
			var b: Buf<Float32> = try context.makeMatrix(rows: 3, columns: 5)
			let c: Sym = try matmul(type: Float.self, square(a), square(b))
			let d: Buf<Float32> = try context.makeMatrix(rows: c.rows, columns: c.columns)
			try context.eval {
				print("a")
				(0..<a.rows).forEach { r in
					(0..<a.columns).forEach { c in
						a[r,c] = ( r + c < ( a.rows + a.columns ) / 2 + 1 ) ? Float32((r+1) * (c+1)) : 0
						print(a[r,c], terminator: ",")
					}
					print("")
				}
				print("b")
				(0..<b.rows).forEach { r in
					(0..<b.columns).forEach { c in
						b[r,c] = ( r + c < ( b.rows + b.columns ) / 2 + 1 ) ? 1 : 0
						print(b[r,c], terminator: ",")
					}
					print("")
				}
			}
			try context.eval(task: store(to: d, from: c))
			print("c")
			try context.eval {
				(0..<d.rows).forEach { r in
					(0..<d.columns).forEach { c in
						print(d[r, c], terminator: ",")
					}
					print("")
				}
			}
			try context.join()
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
	*/
	/*
	func testRNG() {
	let cnt: Int = 64
	let cap: Int = 1024 * 1024 * 64
	let ref: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: cap)
	defer {
	ref.deallocate(capacity: cap)
	}
	let arc: Date = Date()
	Array(repeating: (), count: cnt).forEach {
	arc4random_buf(ref, cap)
	}
	print("arc", -arc.timeIntervalSinceNow)
	let sec: Date = Date()
	Array(repeating: (), count: cnt).forEach {
	SecRandomCopyBytes(kSecRandomDefault, cap, ref)
	}
	print("sec", -sec.timeIntervalSinceNow)
	}
	*/
}

