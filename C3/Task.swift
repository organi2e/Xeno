//
//  Task.swift
//  C3
//
//  Created by Kota Nakano on 4/3/18.
//
import Accelerate
import MetalPerformanceShaders
public protocol Task {
	func eval(commandBuffer: MTLCommandBuffer) throws
}
