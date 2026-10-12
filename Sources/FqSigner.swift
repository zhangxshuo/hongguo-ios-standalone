import Foundation

enum FqSignerError: LocalizedError {
    case missingResource(String)
    case invalidResponse
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            return "缺少内置资源: \(name)"
        case .invalidResponse:
            return "内置签名器返回无效数据"
        case .failed(let message):
            return message
        }
    }
}

struct FqSignRequest: Encodable {
    let so_path: String
    let cpp_path: String
    let cert_path: String
    let url: String
    let headers: [String: String]
    let header_order: [String]
    let timestamp: UInt64
    let aid: UInt32
    let device_id: String
    let version_name: String
}

struct FqSignResponse: Decodable {
    let ok: Bool
    let headers: [String: String]?
    let error: String?
}

final class FqSigner {
    static let shared = FqSigner()

    private let soPath: String
    private let cppPath: String
    private let certPath: String
    private let queue = DispatchQueue(label: "cn.guoban.hongguo.signer")

    private init() {
        soPath = Bundle.main.path(forResource: "libmetasec_ml", ofType: "so") ?? ""
        cppPath = Bundle.main.path(forResource: "libc++_shared", ofType: "so") ?? ""
        certPath = Bundle.main.path(forResource: "ms_16777218", ofType: "bin") ?? ""
    }

    func sign(url: String, headers: [String: String], order: [String]) throws -> [String: String] {
        try queue.sync {
            try performSign(url: url, headers: headers, order: order)
        }
    }

    private func performSign(url: String, headers: [String: String], order: [String]) throws -> [String: String] {
        guard !soPath.isEmpty else { throw FqSignerError.missingResource("libmetasec_ml.so") }
        guard !cppPath.isEmpty else { throw FqSignerError.missingResource("libc++_shared.so") }
        guard !certPath.isEmpty else { throw FqSignerError.missingResource("ms_16777218.bin") }

        let request = FqSignRequest(
            so_path: soPath,
            cpp_path: cppPath,
            cert_path: certPath,
            url: url,
            headers: headers,
            header_order: order,
            timestamp: UInt64(Date().timeIntervalSince1970 * 1000),
            aid: 8662,
            device_id: "4223674528607515",
            version_name: "7.2.2.32"
        )
        let requestData = try JSONEncoder().encode(request)
        guard let requestText = String(data: requestData, encoding: .utf8) else {
            throw FqSignerError.invalidResponse
        }

        let resultPointer = requestText.withCString { pointer in
            hongguo_sign(pointer)
        }
        guard let resultPointer else {
            throw FqSignerError.invalidResponse
        }
        defer { hongguo_free_string(resultPointer) }

        let resultText = String(cString: resultPointer)
        guard let resultData = resultText.data(using: .utf8) else {
            throw FqSignerError.invalidResponse
        }
        let response = try JSONDecoder().decode(FqSignResponse.self, from: resultData)
        guard response.ok, let headers = response.headers else {
            throw FqSignerError.failed(response.error ?? "签名失败")
        }
        return headers
    }
}
