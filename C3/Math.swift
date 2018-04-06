//
//  math.swift
//  C3
//
//  Created by Kota Nakano on 4/6/18.
//
import Foundation
public func fma(_ a: Sym, _ b: Sym, _ c: Sym) throws -> Sym {
	switch (a.xtype, b.xtype, c.xtype) {
	case is (Float16.Type, Float16.Type, Float16.Type):
		return try map(type: Float16.self, lambda: "fma(a, b, c)", source: ["a": a, "b": b, "c": c])
	case is (Float32.Type, Float32.Type, Float32.Type):
		return try map(type: Float32.self, lambda: "fma(a, b, c)", source: ["a": a, "b": b, "c": c])
	default:
		assertionFailure()
		throw ErrorCases.any
	}
}
public func sin(_ x: Sym) throws -> Sym {
	switch x.xtype {
	case is Float16.Type, is Float32.Type:
		return try map(type: x.xtype, lambda: "sin(x)", source: ["x": x])
	default:
		assertionFailure()
		return x
	}
}
public func cos(_ x: Sym) throws -> Sym {
	switch x.xtype {
	case is Float16.Type, is Float32.Type:
		return try map(type: x.xtype, lambda: "cos(x)", source: ["x": x])
	default:
		assertionFailure()
		return x
	}
}
public func tan(_ x: Sym) throws -> Sym {
	switch x.xtype {
	case is Float16.Type, is Float32.Type:
		return try map(type: x.xtype, lambda: "tan(x)", source: ["x": x])
	default:
		assertionFailure()
		return x
	}
}
