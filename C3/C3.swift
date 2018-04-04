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
struct Float16 {
	let data: UInt16
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

