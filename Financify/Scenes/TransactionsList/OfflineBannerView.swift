import SwiftUI

struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
            Text("Оффлайн-режим")
        }
        .font(.footnote.weight(.medium))
        .foregroundColor(.white)
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.secondAccent)
    }
}
