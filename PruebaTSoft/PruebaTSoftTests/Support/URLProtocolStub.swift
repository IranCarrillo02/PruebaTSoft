import Foundation

final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    struct Stub {
        let statusCode: Int
        let data: Data
    }

    nonisolated(unsafe) static var stubs: [String: Stub] = [:]

    static func stub(url: URL, statusCode: Int = 200, data: Data) {
        stubs[url.absoluteString] = Stub(statusCode: statusCode, data: data)
    }

    static func reset() {
        stubs.removeAll()
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let stub = Self.stubs[url.absoluteString] else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let response = HTTPURLResponse(url: url, statusCode: stub.statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
