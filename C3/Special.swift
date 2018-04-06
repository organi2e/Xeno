//
//  Special.swift
//  C3
//
//  Created by Kota Nakano on 4/6/18.
//
private let erf: String = """
template<typename T> T erf(T const z) {
	T const v = 1.0 / fma(fabs(z), 0.5, 1.0);
	T const w[] = {
		0.17087277,
		-0.82215223,
		1.48851587,
		-1.13520398,
		0.27886807,
		-0.18628806,
		0.09678418,
		0.37409196,
		1.00002368,
		1.26551223
	};
	return copysign(fma(-v,
						exp(
							fma(v,
								fma(v,
									fma(v,
										fma(v,
											fma(v,
												fma(v,
													fma(v,
														fma(v,
															fma(v,
																w[0],
																w[1]),
															w[2]),
														w[3]),
													w[4]),
												w[5]),
											w[6]),
										w[7]),
									w[8]),
								- fma(z, z, w[9]))),
						1),
					z);
}
"""
private let erfinv: String = """
//refer: Mike Giles, ``Approximating the erfinv function, ''
template<typename T> T erfinv(T const x) {
	T const f[] = {
		2.81022636e-08,
		3.43273939e-07,
		-3.5233877e-06,
		-4.39150654e-06,
		0.00021858087,
		-0.00125372503,
		-0.00417768164,
		0.246640727,
		1.50140941};
	T const g[] = {
		-0.000200214257,
		0.000100950558,
		0.00134934322,
		-0.00367342844,
		0.00573950773,
		-0.0076224613,
		0.00943887047,
		1.00167406,
		2.83297682
	};
	T const z = - log ( - fma ( x, x, -1 ) );
	auto const s = z < 5.0;
	T const w = select(sqrt(z) - 3.0, z - 2.5, s);
	return x * fma(w,
				   fma(w,
					   fma(w,
						   fma(w,
							   fma(w,
								   fma(w,
									   fma(w,
										   fma(w, select(g[0], f[0], s),
											   select(g[1], f[1], s)),
										   select(g[2], f[2], s)),
									   select(g[3], f[3], s)),
								   select(g[4], f[4], s)),
							   select(g[5], f[5], s)),
						   select(g[6], f[6], s)),
					   select(g[7], f[7], s)),
				   select(g[8], f[8], s));
}
"""
public func erf(_ x: Sym) throws -> Sym {
	switch x.xtype {
	case is Float16.Type, is Float32.Type:
		return try map(type: x.xtype, lambda: "erf(x)", source: ["x": x], extra: erf)
	default:
		assertionFailure()
		return x
	}
}
public func erfinv(_ x: Sym) throws -> Sym {
	switch x.xtype {
	case is Float16.Type, is Float32.Type:
		return try map(type: x.xtype, lambda: "erfinv(x)", source: ["x": x], extra: erfinv)
	default:
		assertionFailure()
		return x
	}
}
