import SwiftUI

struct LoadingAnimation: View {
    @State private var start = false
    
    var body: some View {
        ZStack {
            Text("Загрузка...")
                .foregroundColor(.secondary)
            
            Text("Загрузка...")
                .foregroundColor(.white)
            
                .frame(width: 200, height: 50)
                .background(.accent)
                .mask {
                    Circle()
                        .frame(width: 40, height: 40)
                        .offset(x: start ? -30 : 30)
                }
            
            Circle()
                .stroke(.accent, lineWidth: 5)
                .frame(width: 40, height: 40)
                .offset(x: start ? -30 : 30)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                start = true
            }
        }
    }
}
