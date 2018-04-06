//
//  C3.swift
//  C3
//
//  Created by Kota Nakano on 3/29/18.
//
import Accelerate
import MetalPerformanceShaders
enum ErrorCases: Error {
	case any
}
public struct Float16 {
	let data: UInt16
	init(from: Float32) {
		data = 0
	}
	var float32: Float32 {
		return 0
	}
}
public protocol XType {
	static var mpsType: MPSDataType { get }
	static var mtlType: MTLDataType { get }
	static var description: String { get }
}
extension XType {
	static var size: Int {
		return MemoryLayout<Self>.stride
	}
	static var stride: Int {
		return MemoryLayout<Self>.stride
	}
}
func copy<X, L>(from: UnsafePointer<X>, to: UnsafeMutablePointer<L>, count: Int) where X : XType {
	let length: vDSP_Length = vDSP_Length(count)
	switch (from, to) {
	case let (from, to) as (UnsafePointer<UInt8>, UnsafeMutablePointer<Float32>):
		vDSP_vfltu8(from, 1, to, 1, length)
	case let (from, to) as (UnsafePointer<UInt8>, UnsafeMutablePointer<Float64>):
		vDSP_vfltu8D(from, 1, to, 1, length)
	case let (from, to) as (UnsafePointer<UInt16>, UnsafeMutablePointer<Float32>):
		vDSP_vfltu16(from, 1, to, 1, length)
	case let (from, to) as (UnsafePointer<UInt16>, UnsafeMutablePointer<Float64>):
		vDSP_vfltu16D(from, 1, to, 1, length)
	case let (from, to) as (UnsafePointer<UInt32>, UnsafeMutablePointer<Float32>):
		vDSP_vfltu32(from, 1, to, 1, length)
	case let (from, to) as (UnsafePointer<UInt32>, UnsafeMutablePointer<Float64>):
		vDSP_vfltu32D(from, 1, to, 1, length)
	case let (from, to) as (UnsafePointer<Int8>, UnsafeMutablePointer<Float32>):
		vDSP_vflt8(from, 1, to, 1, length)
	case let (from, to) as (UnsafePointer<Int8>, UnsafeMutablePointer<Float64>):
		vDSP_vflt8D(from, 1, to, 1, length)
	case let (from, to) as (UnsafePointer<Int16>, UnsafeMutablePointer<Float32>):
		vDSP_vflt16(from, 1, to, 1, length)
	case let (from, to) as (UnsafePointer<Int16>, UnsafeMutablePointer<Float64>):
		vDSP_vflt16D(from, 1, to, 1, length)
//	case let (from, to) as (UnsafePointer<Float32>, UnsafeMutablePointer<Float32>):
//		assertionFailure("not implemented")
//	case let (from, to) as (UnsafePointer<Float64>, UnsafeMutablePointer<Float64>):
//		assertionFailure("not implemented")
	case let (from, to) as (UnsafePointer<Float32>, UnsafeMutablePointer<Float32>):
		cblas_scopy(Int32(count), from, 1, to, 1)
	case let (from, to) as (UnsafePointer<Float32>, UnsafeMutablePointer<Float64>):
		vDSP_vspdp(from, 1, to, 1, length)
	default:
		assertionFailure()
	}
}
extension UInt8: XType {
	public static let mpsType: MPSDataType = .uInt8
	public static let mtlType: MTLDataType = .uchar
	public static let description: String = "uint"
}
extension UInt16: XType {
	public static let mpsType: MPSDataType = .uInt16
	public static let mtlType: MTLDataType = .ushort
	public static let description: String = "ushort"
}
extension UInt32: XType {
	public static let mpsType: MPSDataType = .uInt32
	public static let mtlType: MTLDataType = .uint
	public static let description: String = "uint"
}
extension Int8: XType {
	public static let mpsType: MPSDataType = .int8
	public static let mtlType: MTLDataType = .char
	public static let description: String = "char"
}
extension Int16: XType {
	public static let mpsType: MPSDataType = .int16
	public static let mtlType: MTLDataType = .short
	public static let description: String = "short"
}
extension Float16: XType {
	public static let mpsType: MPSDataType = .float16
	public static let mtlType: MTLDataType = .half
	public static let description: String = "half"
}
extension Float32: XType {
	public static let mpsType: MPSDataType = .float32
	public static let mtlType: MTLDataType = .float
	public static let description: String = "float"
}
extension Bool {
	static let T: Bool = true
	static let F: Bool = false
}
typealias MPSType = XType
extension MTLFunctionConstantValues {
	func binding<T>(value: T, for name: String) -> Self where T : XType {
		setConstantValue([value], type: T.mtlType, withName: name)
		return self
	}
	func binding<T>(value: T, for index: Int) -> Self where T : XType {
		setConstantValue([value], type: T.mtlType, index: index)
		return self
	}
}

