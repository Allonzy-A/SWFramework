import SwiftUI
import UIKit

// MARK: - Status Bar Modifiers

// Модификаторы для управления статус баром
public struct StatusBarModifiers {
    
    // Модификатор для скрытия статус бара
    public struct StatusBarHiddenModifier: ViewModifier {
        let isHidden: Bool
        
        public func body(content: Content) -> some View {
            content
                .onAppear {
                    setStatusBarVisibility(isHidden)
                }
                .onChange(of: isHidden) { newValue in
                    setStatusBarVisibility(newValue)
                }
        }
        
        private func setStatusBarVisibility(_ hidden: Bool) {
            // Используем более безопасный метод без прямых манипуляций с окнами
            DispatchQueue.main.async {
                // Отправляем уведомление об изменении видимости статус бара
                NotificationCenter.default.post(
                    name: UIApplication.statusBarOrientationDidChangeNotification,
                    object: nil
                )
                
                // Приложение должно иметь настройку в Info.plist
                // UIViewControllerBasedStatusBarAppearance = NO для этого подхода
                
                // Если нужна полная поддержка, следует расширить базовый контроллер
                // и переопределить prefersStatusBarHidden
            }
        }
    }
}

// Расширения для удобного доступа к модификаторам
public extension View {
    func statusBarHidden(_ hidden: Bool = true) -> some View {
        self.modifier(StatusBarModifiers.StatusBarHiddenModifier(isHidden: hidden))
    }
} 