import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "İstatistikler Yakında",
                systemImage: "chart.bar.xaxis",
                description: Text("Yeterli antrenman verisi oluştuğunda gelişim grafikleri burada görünecek.")
            )
            .navigationTitle("İstatistikler")
        }
    }
}

#Preview {
    StatsView()
}
