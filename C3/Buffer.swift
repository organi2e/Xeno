//
//  Buffer.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import Accelerate
import MetalPerformanceShaders
public class Buf<X> where X : XType {
	public let rows: Int
	public let columns: Int
	let buffer: MTLBuffer
	init(device: MTLDevice, rows r: Int, columns c: Int) throws {
		rows = r
		columns = c
		buffer = try device.makeBuffer(length: rows * columns * X.stride, options: .storageModeShared)
	}
}
extension Buf : Sym {
	public var xtype: XType.Type {
		return X.self
	}
	public var device: MTLDevice {
		return buffer.device
	}
	public func eval(commandBuffer: MTLCommandBuffer) throws -> MTLBuffer {
		return buffer
	}
}
extension Buf {
	public subscript(_ index: Int) -> X {
		get {
			assert(0 <= index && index < rows * columns)
			return buffer.contents().assumingMemoryBound(to: X.self).advanced(by: index).pointee
		}
		set {
			assert(0 <= index && index < rows * columns)
			buffer.contents().assumingMemoryBound(to: X.self).advanced(by: index).pointee = newValue
		}
	}
	public subscript(_ r: Int, _ c: Int) -> X {
		get {
			assert(0 <= r && r < rows)
			assert(0 <= c && c < columns)
			let index: Int = r * columns + c
			return buffer.contents().assumingMemoryBound(to: X.self).advanced(by: index).pointee
		}
		set {
			assert(0 <= r && r < rows)
			assert(0 <= c && c < columns)
			let index: Int = r * columns + c
			buffer.contents().assumingMemoryBound(to: X.self).advanced(by: index).pointee = newValue
		}
	}
}
extension Buf {
	var array: Array<X> {
		return Array(UnsafeBufferPointer(start: buffer.contents().assumingMemoryBound(to: X.self), count: rows * columns))
	}
}
extension Buf where X == Float32 {
	func fetch() -> la_object_t {
		return la_matrix_from_float_buffer_nocopy(buffer.contents().assumingMemoryBound(to: X.self), la_count_t(rows), la_count_t(columns), la_count_t(columns), .none, nil, .default)
	}
	func store(value: la_object_t) {
		assert(rows == Int(la_matrix_rows(value)))
		assert(columns == Int(la_matrix_cols(value)))
		let status: la_status_t = la_matrix_to_float_buffer(buffer.contents().assumingMemoryBound(to: X.self), la_count_t(columns), value)
		assert(status == .success)
	}
}
extension Context {
	public func makeMatrix<X>(rows: Int, columns: Int) throws -> Buf<X> where X : XType {
		return try Buf<X>(device: device, rows: rows, columns: columns)
	}
}
public protocol MPSArray {
	var count: Int { get }
	var rows: Int { get }
	var columns: Int { get }
	var width: Int { get }
	var contents: UnsafeMutableRawPointer { get }
	var dataType: MPSDataType { get }
	var data: MTLBuffer { get }
	var device: MTLDevice { get }
}
extension MPSVector: MPSArray {
	public var count: Int {
		return vectors
	}
	public var rows: Int {
		return 1
	}
	public var columns: Int {
		return length
	}
	public var width: Int {
		return vectorBytes
	}
	public var contents: UnsafeMutableRawPointer {
		return data.contents()
	}
}
extension MPSMatrix: MPSArray {
	public var count: Int {
		return matrices
	}
//	public func fetch<T>(offset: Int) -> T where T : MPSType {
//		return data.contents().advanced(by: offset).assumingMemoryBound(to: T.self).pointee
//	}
//	public func store<T>(offset: Int, newValue: T) where T : MPSType {
//		data.contents().advanced(by: offset).assumingMemoryBound(to: T.self).pointee = newValue
//	}
	public var width: Int {
		return matrixBytes
	}
	public var contents: UnsafeMutableRawPointer {
		return data.contents()
	}
}
struct Buffer<T> where T : MPSType {
	let array: MPSArray
}
extension Buffer: Symbol {
	public var count: Int {
		return array.count
	}
	public var rows: Int {
		return array.rows
	}
	public var columns: Int {
		return array.columns
	}
	public var transpose: Bool {
		return false
	}
	public var type: MPSType.Type {
		return T.self
	}
	public var dataType: MPSDataType {
		return array.dataType
	}
	public var device: MTLDevice {
		return array.device
	}
	public func eval(commandBuffer: MTLCommandBuffer) throws -> MPSArray {
		return array
	}
}
extension Buffer {
	subscript(_ index: Int) -> T {
		get {
			return array.data.contents().assumingMemoryBound(to: T.self).advanced(by: index).pointee
		}
		set {
			array.data.contents().assumingMemoryBound(to: T.self).advanced(by: index).pointee = newValue
		}
	}
}
/*
extension Buffer {
	func store<A>(object: LazyArray<A>) where T == Int8 {
		assert( count == 1 )
		object.eval(to: unsafeRef)
	}
	func store<A>(object: LazyArray<A>) where T == Int16 {
		assert( count == 1 )
		object.eval(to: unsafeRef)
	}
}
extension Buffer {
	func store<A>(object: LazyArray<A>) where T == UInt8 {
		assert( count == 1 )
		object.eval(to: unsafeRef)
	}
	func store<A>(object: LazyArray<A>) where T == UInt16 {
		assert( count == 1 )
		object.eval(to: unsafeRef)
	}
	func store<A>(object: LazyArray<A>) where T == UInt32 {
		assert( count == 1 )
		object.eval(to: unsafeRef)
	}
}
extension Buffer {
	func store<A>(object: LazyArray<A>) where T == Float32 {
		assert(count == 1)
		T.la2Float32(from: object.object, to: unsafeRef)
	}
}
*/
extension Buffer where T == Float32 {
	func store(objects: Array<la_object_t>) {
		let p: UnsafeMutableRawPointer = array.contents
		let rows: la_count_t = la_count_t(array.rows)
		let columns: la_count_t = la_count_t(array.columns)
		let width: Int = array.width
		assert(objects.count == count)
		objects.enumerated().forEach {
			assert(rows == la_matrix_rows($1))
			assert(columns == la_matrix_cols($1))
			let success: Bool = la_matrix_to_float_buffer(p.advanced(by: $0 * width).assumingMemoryBound(to: T.self), columns, $1) == la_status_t(LA_SUCCESS)
			assert(success)
		}
	}
	func fetch() -> Array<la_object_t> {
		let p: UnsafeMutableRawPointer = array.contents
		let rows: la_count_t = la_count_t(array.rows)
		let columns: la_count_t = la_count_t(array.columns)
		let width: Int = array.width
		return (0..<array.count).map {
			la_matrix_from_float_buffer(p.advanced(by: $0 * width).assumingMemoryBound(to: T.self), rows, columns, columns, .none, .default)
		}
	}
	var unsafeLazy: Array<la_object_t> {
		let p: UnsafeMutableRawPointer = array.contents
		let rows: la_count_t = la_count_t(array.rows)
		let columns: la_count_t = la_count_t(array.columns)
		let width: Int = array.width
		return (0..<array.count).map {
			la_matrix_from_float_buffer_nocopy(p.advanced(by: $0 * width).assumingMemoryBound(to: T.self), rows, columns, columns, .none, nil, .default)
		}
	}
}
extension Context {
	func makeBuffer<T>(length: Int) throws -> Buffer<T> where T : MPSType {
		let scalarBytes: Int = T.stride
		guard let buffer: MTLBuffer = device.makeBuffer(length: length * scalarBytes, options: .storageModeShared) else {
			throw ErrorCases.any
		}
		let descriptor: MPSVectorDescriptor = MPSVectorDescriptor(length: length, dataType: T.mpsType)
		return Buffer<T>(array: MPSVector(buffer: buffer, descriptor: descriptor))
	}
	func makeBuffer<T>(count: Int, length: Int) throws -> Buffer<T> where T : MPSType {
		let vectorBytes: Int = length * T.stride
		guard let buffer: MTLBuffer = device.makeBuffer(length: count * vectorBytes, options: .storageModeShared) else {
			throw ErrorCases.any
		}
		let descriptor: MPSVectorDescriptor = MPSVectorDescriptor(length: length, vectors: count, vectorBytes: vectorBytes, dataType: T.mpsType)
		return Buffer<T>(array: MPSVector(buffer: buffer, descriptor: descriptor))
	}
}
extension Context {
	func makeBuffer<T>(rows: Int, columns: Int) throws -> Buffer<T> where T : MPSType {
		let rowBytes: Int = columns * T.stride
		guard let buffer: MTLBuffer = device.makeBuffer(length: rows * rowBytes, options: .storageModeShared) else {
			throw ErrorCases.any
		}
		let descriptor: MPSMatrixDescriptor = MPSMatrixDescriptor(rows: rows, columns: columns, rowBytes: rowBytes, dataType: T.mpsType)
		return Buffer(array: MPSMatrix(buffer: buffer, descriptor: descriptor))
	}
	func makeBuffer<T>(count: Int, rows: Int, columns: Int) throws -> Buffer<T>  where T : MPSType {
		let rowBytes: Int = columns * T.stride
		let matrixBytes: Int = rows * rowBytes
		guard let buffer: MTLBuffer = device.makeBuffer(length: count * matrixBytes, options: .storageModeShared) else {
			throw ErrorCases.any
		}
		let descriptor: MPSMatrixDescriptor = MPSMatrixDescriptor(rows: rows, columns: columns, matrices: count, rowBytes: rowBytes, matrixBytes: matrixBytes, dataType: T.mpsType)
		return Buffer(array: MPSMatrix(buffer: buffer, descriptor: descriptor))
	}
}
