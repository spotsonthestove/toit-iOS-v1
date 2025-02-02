import XCTest
@testable import toit_iOS_v1

final class APIClientTests: XCTestCase {
    var sut: APIClient!
    var session: URLSession!
    
    override func setUp() {
        super.setUp()
        
        // Create URL Session configuration that allows us to mock network calls
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
        
        sut = APIClient(session: session)
    }
    
    override func tearDown() {
        sut = nil
        session = nil
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockError = nil
        super.tearDown()
    }
    
    func testSuccessfulGETRequest() async throws {
        // Given
        let mockResponse = MindMapsResponse(mindmaps: [
            MindMap(id: "1", name: "Test Map", description: "Test Description", createdAt: Date(), nodes: [])
        ])
        let mockData = try JSONEncoder().encode(mockResponse)
        
        MockURLProtocol.mockData = mockData
        
        // When
        let response: MindMapsResponse = try await sut.get(endpoint: "/api/data", token: "test-token")
        
        // Then
        XCTAssertEqual(response.mindmaps.count, 1)
        XCTAssertEqual(response.mindmaps[0].name, "Test Map")
    }
    
    func testUnauthorizedError() async {
        // Given
        MockURLProtocol.mockError = APIError.unauthorized
        
        // When/Then
        do {
            let _: MindMapsResponse = try await sut.get(endpoint: "/api/data", token: "invalid-token")
            XCTFail("Expected unauthorized error")
        } catch {
            XCTAssertTrue(error is APIError)
            XCTAssertEqual(error as? APIError, .unauthorized)
        }
    }
    
    func testInvalidURLError() async {
        // When/Then
        do {
            let _: MindMapsResponse = try await sut.get(endpoint: "\\invalid-url", token: nil)
            XCTFail("Expected invalid URL error")
        } catch {
            XCTAssertTrue(error is APIError)
            XCTAssertEqual(error as? APIError, .invalidURL)
        }
    }
}

// MARK: - Mock URL Protocol
class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockError: Error?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        if let data = MockURLProtocol.mockData {
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
} 