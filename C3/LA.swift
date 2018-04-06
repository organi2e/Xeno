//
//  La.swift
//  An implementation of la_object_t with typedata
//
//  Created by Kota Nakano on 3/30/18.
//
import Accelerate
import MetalPerformanceShaders
public protocol LazyType {
	static var from: (UnsafePointer<Self>, la_count_t, la_count_t, la_count_t, la_hint_t, la_attribute_t) -> la_object_t { get }
	static var to: (UnsafeMutablePointer<Self>, la_count_t, la_object_t) -> la_status_t { get }
	static var scale: (la_object_t, Self) -> la_object_t { get }
	
	static var fromSInt8: (UnsafePointer<Int8>, vDSP_Stride, UnsafeMutablePointer<Self>, vDSP_Stride, vDSP_Length) -> Void { get }
	static var fromSInt16: (UnsafePointer<Int16>, vDSP_Stride, UnsafeMutablePointer<Self>, vDSP_Stride, vDSP_Length) -> Void { get }
	static var fromSInt32: (UnsafePointer<Int32>, vDSP_Stride, UnsafeMutablePointer<Self>, vDSP_Stride, vDSP_Length) -> Void { get }
	
	static var fromUInt8: (UnsafePointer<UInt8>, vDSP_Stride, UnsafeMutablePointer<Self>, vDSP_Stride, vDSP_Length) -> Void { get }
	static var fromUInt16: (UnsafePointer<UInt16>, vDSP_Stride, UnsafeMutablePointer<Self>, vDSP_Stride, vDSP_Length) -> Void { get }
	static var fromUInt32: (UnsafePointer<UInt32>, vDSP_Stride, UnsafeMutablePointer<Self>, vDSP_Stride, vDSP_Length) -> Void { get }
	
	static var toSInt8: (UnsafePointer<Self>, vDSP_Stride, UnsafeMutablePointer<Int8>, vDSP_Stride, vDSP_Length) -> Void { get }
	static var toSInt16: (UnsafePointer<Self>, vDSP_Stride, UnsafeMutablePointer<Int16>, vDSP_Stride, vDSP_Length) -> Void { get }
	static var toSInt32: (UnsafePointer<Self>, vDSP_Stride, UnsafeMutablePointer<Int32>, vDSP_Stride, vDSP_Length) -> Void { get }
	
	static var toUInt8: (UnsafePointer<Self>, vDSP_Stride, UnsafeMutablePointer<UInt8>, vDSP_Stride, vDSP_Length) -> Void { get }
	static var toUInt16: (UnsafePointer<Self>, vDSP_Stride, UnsafeMutablePointer<UInt16>, vDSP_Stride, vDSP_Length) -> Void { get }
	static var toUInt32: (UnsafePointer<Self>, vDSP_Stride, UnsafeMutablePointer<UInt32>, vDSP_Stride, vDSP_Length) -> Void { get }
	
	static func toFloat32(from: UnsafePointer<Self>, to: UnsafeMutablePointer<Float32>, count: Int)
	static func toFloat64(from: UnsafePointer<Self>, to: UnsafeMutablePointer<Float64>, count: Int)
	
	static func la2Float32(from: la_object_t, to: UnsafeMutablePointer<Float32>)
	static func la2Float64(from: la_object_t, to: UnsafeMutablePointer<Float64>)
	
	static var cos: (UnsafeMutablePointer<Self>, UnsafePointer<Self>, UnsafePointer<Int32>) -> Void { get }
	static var sin: (UnsafeMutablePointer<Self>, UnsafePointer<Self>, UnsafePointer<Int32>) -> Void { get }
	static var exp: (UnsafeMutablePointer<Self>, UnsafePointer<Self>, UnsafePointer<Int32>) -> Void { get }
	static var log: (UnsafeMutablePointer<Self>, UnsafePointer<Self>, UnsafePointer<Int32>) -> Void { get }
	
}
extension Float32 : LazyType {
	
	public static let from = la_matrix_from_float_buffer
	public static let to = la_matrix_to_float_buffer
	public static let scale = la_scale_with_float
	
	public static let fromSInt8 = vDSP_vflt8
	public static let fromSInt16 = vDSP_vflt16
	public static let fromSInt32 = vDSP_vflt32
	
	public static let fromUInt8 = vDSP_vfltu8
	public static let fromUInt16 = vDSP_vfltu16
	public static let fromUInt32 = vDSP_vfltu32

	public static let toSInt8 = vDSP_vfix8
	public static let toSInt16 = vDSP_vfix16
	public static let toSInt32 = vDSP_vfix32
	
	public static let toUInt8 = vDSP_vfixu8
	public static let toUInt16 = vDSP_vfixu16
	public static let toUInt32 = vDSP_vfixu32
	
	public static let cos = vvcosf
	public static let sin = vvsinf
	public static let exp = vvexpf
	public static let log = vvlogf
	
	public static func toFloat32(from: UnsafePointer<Float32>, to: UnsafeMutablePointer<Float32>, count: Int) {
		cblas_scopy(Int32(count), from, 1, to, 1)
	}
	public static func toFloat64(from: UnsafePointer<Float32>, to: UnsafeMutablePointer<Float64>, count: Int) {
		vDSP_vspdp(from, 1, to, 1, vDSP_Length(count))
	}
	public static func la2Float32(from: la_object_t, to: UnsafeMutablePointer<Float32>) {
		let status: la_status_t = la_matrix_to_float_buffer(to, la_matrix_cols(from), from)
		assert(status == .success)
	}
	public static func la2Float64(from: la_object_t, to: UnsafeMutablePointer<Float64>) {
		let count: Int = Int(la_matrix_rows(from) * la_matrix_cols(from))
		Data(capacity: count * MemoryLayout<Float32>.stride).withUnsafeBytes { (src: UnsafePointer<Float32>) in
			la2Float32(from: from, to: UnsafeMutablePointer(mutating: src))
			toFloat64(from: src, to: to, count: count)
		}
	}
}
extension Float64 : LazyType {
	
	public static let from = la_matrix_from_double_buffer
	public static let to = la_matrix_to_double_buffer
	public static let scale = la_scale_with_double
	
	public static let fromSInt8 = vDSP_vflt8D
	public static let fromSInt16 = vDSP_vflt16D
	public static let fromSInt32 = vDSP_vflt32D
	
	public static let fromUInt8 = vDSP_vfltu8D
	public static let fromUInt16 = vDSP_vfltu16D
	public static let fromUInt32 = vDSP_vfltu32D
	
	public static let toSInt8 = vDSP_vfix8D
	public static let toSInt16 = vDSP_vfix16D
	public static let toSInt32 = vDSP_vfix32D
	
	public static let toUInt8 = vDSP_vfixu8D
	public static let toUInt16 = vDSP_vfixu16D
	public static let toUInt32 = vDSP_vfixu32D
	
	public static let cos = vvcos
	public static let sin = vvsin
	public static let exp = vvexp
	public static let log = vvlog
	
	public static func toFloat32(from: UnsafePointer<Float64>, to: UnsafeMutablePointer<Float32>, count: Int) {
		vDSP_vdpsp(from, 1, to, 1, vDSP_Length(count))
	}
	public static func toFloat64(from: UnsafePointer<Float64>, to: UnsafeMutablePointer<Float64>, count: Int) {
		cblas_dcopy(Int32(count), to, 1, to, 1)
	}
	public static func la2Float32(from: la_object_t, to: UnsafeMutablePointer<Float32>) {
		let count: Int = Int(la_matrix_rows(from) * la_matrix_cols(from))
		Data(capacity: count * MemoryLayout<Float64>.stride).withUnsafeBytes { (src: UnsafePointer<Float64>) in
			la2Float64(from: from, to: UnsafeMutablePointer(mutating: src))
			toFloat32(from: src, to: to, count: count)
		}
	}
	public static func la2Float64(from: la_object_t, to: UnsafeMutablePointer<Float64>) {
		let status: la_status_t = la_matrix_to_double_buffer(to, la_matrix_cols(from), from)
		assert(status == .success)
	}
}
extension la_hint_t {
	static let none: la_hint_t = la_hint_t(LA_NO_HINT)
}
extension la_attribute_t {
	static let `default`: la_attribute_t = la_attribute_t(LA_DEFAULT_ATTRIBUTES)
}
extension la_status_t {
	static let success: la_status_t = la_status_t(LA_SUCCESS)
}
public struct LazyArray<T> where T : LazyType {
	internal let object: la_object_t
}
extension LazyArray {
	var rows: Int {
		return Int(la_matrix_rows(object))
	}
	var columns: Int {
		return Int(la_matrix_cols(object))
	}
	subscript(_ r: Range<Int>, _ c: Range<Int>) -> LazyArray<T> {
		return LazyArray(object: la_matrix_slice(object, la_index_t(r.lowerBound), la_index_t(c.lowerBound), 1, 1, la_count_t(r.count), la_count_t(c.count)))
	}
	init(rows: Int, columns: Int, values: Array<T>) {
		object = T.from(values, la_count_t(rows), la_count_t(columns), la_count_t(columns), .none, .default)
	}
	func eval(to: UnsafeMutablePointer<T>) {
		let status: la_status_t = T.to(to, la_matrix_cols(object), object)
		assert(status == la_status_t(LA_SUCCESS))
	}
	func eval(to: UnsafeMutablePointer<Int8>) {
		let length: Int = rows * columns
		let capacity: Int = length * MemoryLayout<T>.stride
		Data(capacity: capacity).withUnsafeBytes { (src: UnsafePointer<T>) in
			let status: la_status_t = T.to(UnsafeMutablePointer<T>(mutating: src), la_matrix_cols(object), object)
			assert(status == .success)
			T.toSInt8(src, 1, to, 1, vDSP_Length(length))
		}
	}
	func eval(to: UnsafeMutablePointer<Int16>) {
		let length: Int = rows * columns
		let capacity: Int = length * MemoryLayout<T>.stride
		Data(capacity: capacity).withUnsafeBytes { (src: UnsafePointer<T>) in
			let status: la_status_t = T.to(UnsafeMutablePointer<T>(mutating: src), la_matrix_cols(object), object)
			assert(status == .success)
			T.toSInt16(src, 1, to, 1, vDSP_Length(length))
		}
	}
	func eval(to: UnsafeMutablePointer<Int32>) {
		let length: Int = rows * columns
		let capacity: Int = length * MemoryLayout<T>.stride
		Data(capacity: capacity).withUnsafeBytes { (src: UnsafePointer<T>) in
			let status: la_status_t = T.to(UnsafeMutablePointer<T>(mutating: src), la_matrix_cols(object), object)
			assert(status == .success)
			T.toSInt32(src, 1, to, 1, vDSP_Length(length))
		}
	}
	func eval(to: UnsafeMutablePointer<UInt8>) {
		let length: Int = rows * columns
		let capacity: Int = length * MemoryLayout<T>.stride
		Data(capacity: capacity).withUnsafeBytes { (src: UnsafePointer<T>) in
			let status: la_status_t = T.to(UnsafeMutablePointer<T>(mutating: src), la_matrix_cols(object), object)
			assert(status == .success)
			T.toUInt8(src, 1, to, 1, vDSP_Length(length))
		}
		
	}
	func eval(to: UnsafeMutablePointer<UInt16>) {
		let length: Int = rows * columns
		let capacity: Int = length * MemoryLayout<T>.stride
		Data(capacity: capacity).withUnsafeBytes { (src: UnsafePointer<T>) in
			let status: la_status_t = T.to(UnsafeMutablePointer<T>(mutating: src), la_matrix_cols(object), object)
			assert(status == .success)
			T.toUInt16(src, 1, to, 1, vDSP_Length(length))
		}
	}
	func eval(to: UnsafeMutablePointer<UInt32>) {
		let length: Int = rows * columns
		let capacity: Int = length * MemoryLayout<T>.stride
		Data(capacity: capacity).withUnsafeBytes { (src: UnsafePointer<T>) in
			let status: la_status_t = T.to(UnsafeMutablePointer<T>(mutating: src), la_matrix_cols(object), object)
			assert(status == .success)
			T.toUInt32(src, 1, to, 1, vDSP_Length(length))
		}
	}
}
func *<T>(_ l: T, _ r: LazyArray<T>) -> LazyArray<T> {
	return LazyArray(object: T.scale(r.object, l))
}
func *<T>(_ l: LazyArray<T>, _ r: T) -> LazyArray<T> {
	return LazyArray(object: T.scale(l.object, r))
}
func +<T>(_ l: LazyArray<T>, _ r: LazyArray<T>) -> LazyArray<T> {
	return LazyArray(object: la_sum(l.object, r.object))
}
func -<T>(_ l: LazyArray<T>, _ r: LazyArray<T>) -> LazyArray<T> {
	return LazyArray(object: la_difference(l.object, r.object))
}
func *<T>(_ l: LazyArray<T>, _ r: LazyArray<T>) -> LazyArray<T> {
	return LazyArray(object: la_elementwise_product(l.object, r.object))
}
func matmul<T>(_ w: LazyArray<T>, _ x: LazyArray<T>) -> LazyArray<T> {
	return LazyArray(object: la_matrix_product(w.object, x.object))
}
func inner_product<T>(_ w: LazyArray<T>, _ x: LazyArray<T>) -> LazyArray<T> {
	return LazyArray(object: la_inner_product(w.object, x.object))
}
func outer_product<T>(_ w: LazyArray<T>, _ x: LazyArray<T>) -> LazyArray<T> {
	return LazyArray(object: la_outer_product(w.object, x.object))
}
func solve<T>(_ w: LazyArray<T>, _ y: LazyArray<T>) -> LazyArray<T> {
	return LazyArray(object: la_solve(w.object, y.object))
}
extension la_object_t {
	var rows: Int {
		return Int(la_matrix_rows(self))
	}
	var columns: Int {
		return Int(la_matrix_cols(self))
	}
	var dataType: MPSDataType {
		return .float32
	}
	/*
	func eval(commandBuffer: MTLCommandBuffer) throws -> Buffer {
		let descriptor: MPSMatrixDescriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: columns * MemoryLayout<Float>.stride, dataType: .float32)
		let matrix: MPSTemporaryMatrix = MPSTemporaryMatrix(commandBuffer: commandBuffer, matrixDescriptor: descriptor)
		la_matrix_to_float_buffer(matrix.data.contents().assumingMemoryBound(to: Float.self), la_matrix_cols(self), self)
		return matrix
	}
	*/
}
extension la_object_t {
	var array: [Float] {
		let array: [Float] = [Float](repeating: 0, count: rows * columns)
		let status: la_status_t = la_matrix_to_float_buffer(UnsafeMutablePointer(mutating: array), la_matrix_cols(self), self)
		assert( status == .success )
		return array
	}
}
