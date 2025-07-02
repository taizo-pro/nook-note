import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("NookNote")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("GitHub Discussions MenuBar App")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Coming Soon:")
                    .font(.headline)
                
                Text("• GitHub Discussions integration")
                Text("• Quick note posting")
                Text("• Work log management")
            }
            .font(.caption)
            
            Spacer()
            
            Button("Quit NookNote") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 280, height: 200)
    }
}

#Preview {
    ContentView()
}