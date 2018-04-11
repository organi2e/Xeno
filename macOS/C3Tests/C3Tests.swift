//
//  C3Tests.swift
//  C3Tests
//
//  Created by Kota Nakano on 3/30/18.
//
import Accelerate
import XCTest
@testable import C3
extension la_hint_t {
	static let none: la_hint_t = la_hint_t(LA_NO_HINT)
}
extension la_attribute_t {
	static let `default`: la_attribute_t = la_attribute_t(LA_DEFAULT_ATTRIBUTES)
}
extension String: Error { }
class C3Tests: XCTestCase {
	private let rows: Int = 64
	private let columns: Int = 64
	func evalv(rows: Int, columns: Int, error: Float32, f: (la_object_t, la_object_t, la_object_t)->la_object_t, g: (Sym, Sym, Sym)throws->Sym) {
		do {
			guard let device: MTLDevice = MTLCreateSystemDefaultDevice() else { throw "no device" }
			let context: Context = try Context(device: device)
			let a: Buf<Float32> = try context.eval(symbol: context.makeUniform(type: Float32.self, rows: rows, columns: columns))
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
	func evals(rows: Int, columns: Int, error: Float32, f: (Float32)->Float32, block: (Sym)throws->Sym) {
		do {
			guard let device: MTLDevice = MTLCreateSystemDefaultDevice() else { throw "no device" }
			let context: Context = try Context(device: device)
			let src: Buf<Float32> = try context.eval(symbol: context.makeUniform(type: Float32.self, rows: rows, columns: columns))
			let dst: Buf<Float32> = try context.eval(symbol: block(src))
			try context.join()
			let src_mat: la_object_t = la_matrix_from_float_buffer(src.array.map(f), la_count_t(rows), la_count_t(columns), la_count_t(columns), .none, .default)
			let dst_mat: la_object_t = dst.fetch()
			let Δ: Float32 = la_norm_as_float(la_difference(src_mat, dst_mat), la_norm_t(LA_L2_NORM))
			XCTAssert(Δ/sqrt(Float(rows*columns))<error)
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
	func evalv(rows: Int, columns: Int, error: Float32, f: (la_object_t)->la_object_t, block: (Sym)throws->Sym) {
		do {
			guard let device: MTLDevice = MTLCreateSystemDefaultDevice() else { throw "no device" }
			let context: Context = try Context(device: device)
			let src: Buf<Float32> = try context.eval(symbol: context.makeUniform(type: Float32.self, rows: rows, columns: columns))
			let dst: Buf<Float32> = try context.eval(symbol: block(src))
			try context.join()
			let src_mat: la_object_t = f(src.fetch())
			let dst_mat: la_object_t = dst.fetch()
			let Δ: Float32 = la_norm_as_float(la_difference(src_mat, dst_mat), la_norm_t(LA_L2_NORM))
			XCTAssert(Δ/sqrt(Float(rows*columns))<error)
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
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
	
	func testNormal() {
		eval { context in
			let K: Int = Int(arc4random_uniform(32768)) + 32768
			let n: Sym = try context.makeStdNormal(type: Float32.self, rows: 1, columns: K)
			let μ: Float32 = (2 as Float32).squareRoot()
			let σ: Float32 = .pi
			let x: Sym = try fma(n, σ, μ)
			let a: Buf<Float32> = try context.eval(symbol: x)
			let c: la_object_t = a.fetch()
			var s: la_object_t = a.fetch()
			
			let a1: Float32 = μ
			let m1: Float32 = s.array.reduce(0, +) / Float32(K)
			XCTAssert(abs(a1-m1)<1e-1, "\(m1, a1)")
			
			s = la_elementwise_product(s, c)
			let a2: Float32 = μ * μ + σ * σ
			let m2: Float32 = s.array.reduce(0, +) / Float32(K)
			XCTAssert(abs(log(m2/a2)) < 1e-2, "\(m2, a2)")
			
			s = la_elementwise_product(s, c)
			let a3: Float32 = μ * μ * μ + 3 * μ * σ * σ
			let m3: Float32 = s.array.reduce(0, +) / Float32(K)
			XCTAssert(abs(log(m3/a3)) < 1e-1, "\(m3, a3)")
			
			s = la_elementwise_product(s, c)
			let a4: Float32 = μ * μ * μ * μ + 6 * μ * μ * σ * σ + 3 * σ * σ * σ * σ
			let m4: Float32 = s.array.reduce(0, +) / Float32(K)
			XCTAssert(abs(log(m4/a4)) < 1e-1, "\(m4, a4)")
		}
	}
	func testUniform() {
		eval { context in
			let K: Int = Int(arc4random_uniform(32768)) + 32768
			let a: Buf<Float32> = try context.eval(symbol: context.makeUniform(type: Float32.self, rows: 1, columns: K))
			let c: la_object_t = a.fetch()
			var s: la_object_t = a.fetch()
			
			let m1: Float32 = s.array.reduce(0, +) / Float32(K)
			XCTAssert(abs(log(m1*2))<1e-1, "\(m1, log(m1*2))")
			
			s = la_elementwise_product(s, c)
			let m2: Float32 = s.array.reduce(0, +) / Float32(K)
			XCTAssert(abs(log(m2*3))<1e-1, "\(m2, log(m2*3))")
			
			s = la_elementwise_product(s, c)
			let m3: Float32 = s.array.reduce(0, +) / Float32(K)
			XCTAssert(abs(log(m3*4))<1e-1, "\(m3, log(m3*4))")
			
			s = la_elementwise_product(s, c)
			let m4: Float32 = s.array.reduce(0, +) / Float32(K)
			XCTAssert(abs(log(m4*5))<1e-1, "\(m4, log(m4*5))")
		}
	}
	func testErfinv() {
		evals(rows: rows, columns: columns, error: 1e-3, f: {$0}, block: { try erfinv(erf($0)) })
	}
	func testErf() {
		evals(rows: rows, columns: columns, error: 1e-3, f: erff, block: erf)
	}
	func testCos() {
		evalv(rows: rows, columns: columns, error: 1e-3, f: cosf, block: cos)
	}
	func testSin() {
		evalv(rows: rows, columns: columns, error: 1e-3, f: sinf, block: sin)
	}
	func testTan() {
		evalv(rows: rows, columns: columns, error: 1e-3, f: tanf, block: tan)
	}
	func testFMA() {
		let a: Float32 = 5
		let b: Float32 = 4
		let la: la_object_t = la_splat_from_float(a, .default)
		let lb: la_object_t = la_splat_from_float(b, .default)
		evalv(rows: rows, columns: columns, error: 1e-6, f: { la_sum(la_scale_with_float($0, a), lb) }, block: { try fma($0, a, b) } )
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

