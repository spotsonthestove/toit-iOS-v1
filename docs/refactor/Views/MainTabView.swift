import SwiftUI
import Metal
import MetalKit
import SceneKit

struct MainTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Items", systemImage: "list.bullet")
                }
            
            MindMapView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .tabItem {
                    Label("Mind Map", systemImage: "brain")
                }
            
            Engine3DTestView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .tabItem {
                    Label("3D Test", systemImage: "cube.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings View")
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Item.self, inMemory: true)
} 
