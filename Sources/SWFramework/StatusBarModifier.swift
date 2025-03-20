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
                    updateStatusBarVisibility(isHidden)
                }
                .onChange(of: isHidden) { newValue in
                    updateStatusBarVisibility(newValue)
                }
        }
        
        private func updateStatusBarVisibility(_ hidden: Bool) {
            if #available(iOS 16.0, *) {
                setStatusBarHidden(hidden)
            } else {
                legacySetStatusBarHidden(hidden)
            }
        }
        
        // iOS 16+ статус бар скрытие
        @available(iOS 16.0, *)
        private func setStatusBarHidden(_ hidden: Bool) {
            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes
                    .filter({ $0.activationState == .foregroundActive })
                    .first as? UIWindowScene,
                      let keyWindow = windowScene.windows.first else { return }
                
                let statusBarManager = windowScene.statusBarManager
                let statusBarFrame = statusBarManager?.statusBarFrame ?? .zero
                
                if hidden {
                    // Удаляем существующий, если есть, чтобы избежать дублирования
                    keyWindow.viewWithTag(1234)?.removeFromSuperview()
                    
                    let statusBarView = UIView(frame: statusBarFrame)
                    statusBarView.backgroundColor = .black
                    statusBarView.tag = 1234
                    keyWindow.addSubview(statusBarView)
                    
                    // Убедимся, что view находится поверх всех других элементов
                    keyWindow.bringSubviewToFront(statusBarView)
                } else {
                    keyWindow.viewWithTag(1234)?.removeFromSuperview()
                }
            }
        }
        
        // Для iOS до 16
        private func legacySetStatusBarHidden(_ hidden: Bool) {
            DispatchQueue.main.async {
                guard let window = UIApplication.shared.windows.first,
                      let statusBarManager = window.windowScene?.statusBarManager else { return }
                
                let statusBarFrame = statusBarManager.statusBarFrame
                
                if hidden {
                    // Удаляем существующий, если есть
                    window.viewWithTag(1234)?.removeFromSuperview()
                    
                    let statusBarView = UIView(frame: statusBarFrame)
                    statusBarView.backgroundColor = .black
                    statusBarView.tag = 1234
                    window.addSubview(statusBarView)
                    window.bringSubviewToFront(statusBarView)
                } else {
                    window.viewWithTag(1234)?.removeFromSuperview()
                }
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