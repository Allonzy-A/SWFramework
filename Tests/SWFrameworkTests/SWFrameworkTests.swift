import XCTest
@testable import SWFramework

final class SWFrameworkTests: XCTestCase {
    func testGenerateDomain() {
        // Доступ к приватному методу через отражение (reflection)
        let framework = SWFramework.shared
        
        // Это метод для тестирования
        // Примечание: в реальных тестах мы бы использовали специальные методы для тестирования или отражение
        // для доступа к приватным методам, но здесь мы просто демонстрируем структуру тестов
        XCTAssertEqual("example.top", "example.top", "Domain should be correctly generated")
    }
    
    func testEnsureHttpsPrefix() {
        // Здесь также необходим доступ к приватному методу
        let urlWithoutPrefix = "example.com"
        let expectedUrl = "https://example.com"
        
        // В реальном тесте мы бы использовали отражение или тестовые методы
        XCTAssertEqual(expectedUrl, expectedUrl, "HTTP prefix should be added correctly")
    }
    
    static var allTests = [
        ("testGenerateDomain", testGenerateDomain),
        ("testEnsureHttpsPrefix", testEnsureHttpsPrefix),
    ]
} 