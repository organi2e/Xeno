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
public protocol MPSType {
	static var mpsType: MPSDataType { get }
	static var mtlType: MTLDataType { get }
	static var description: String { get }
	static var suffix: String { get }
}
extension MPSType {
	static var size: Int {
		return MemoryLayout<Self>.stride
	}
	static var stride: Int {
		return MemoryLayout<Self>.stride
	}
}
extension UInt8: MPSType {
	public static let mpsType: MPSDataType = .uInt8
	public static let mtlType: MTLDataType = .uchar
	public static let description: String = "uint"
	public static let suffix: String = "u8"
}
extension UInt16: MPSType {
	public static let mpsType: MPSDataType = .uInt16
	public static let mtlType: MTLDataType = .ushort
	public static let description: String = "ushort"
	public static let suffix: String = "u16"
}
extension UInt32: MPSType {
	public static let mpsType: MPSDataType = .uInt32
	public static let mtlType: MTLDataType = .uint
	public static let description: String = "uint"
	public static let suffix: String = "u32"
}
extension Int8: MPSType {
	public static let mpsType: MPSDataType = .int8
	public static let mtlType: MTLDataType = .char
	public static let description: String = "char"
	public static let suffix: String = "s8"
}
extension Int16: MPSType {
	public static let mpsType: MPSDataType = .int16
	public static let mtlType: MTLDataType = .short
	public static let description: String = "short"
	public static let suffix: String = "s16"
}
extension Float16: MPSType {
	public static let mpsType: MPSDataType = .float16
	public static let mtlType: MTLDataType = .half
	public static let description: String = "half"
	public static let suffix: String = "f16"
}
extension Float32: MPSType {
	public static let mpsType: MPSDataType = .float32
	public static let mtlType: MTLDataType = .float
	public static let description: String = "float"
	public static let suffix: String = "f32"
}
extension MTLFunctionConstantValues {
	func binding<T>(value: T, for name: String) -> Self where T : MPSType {
		setConstantValue([value], type: T.mtlType, withName: name)
		return self
	}
	func binding<T>(value: T, for index: Int) -> Self where T : MPSType {
		setConstantValue([value], type: T.mtlType, index: index)
		return self
	}
}

