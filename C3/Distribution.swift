//
//  Distribution.swift
//  C3
//
//  Created by Kota Nakano on 3/30/18.
//
public protocol Distribution {
	func sample(to: Sym) throws -> Task
	var random: Sym { get }
}
