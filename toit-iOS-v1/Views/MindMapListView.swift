import SwiftUI

class MindMapListViewModel: ObservableObject {
    @Published var mindMaps: [MindMap] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let mindMapService: MindMapServiceProtocol
    
    init(mindMapService: MindMapServiceProtocol = MindMapService()) {
        self.mindMapService = mindMapService
    }
    
    @MainActor
    func fetchMindMaps(token: String) async {
        isLoading = true
        error = nil
        
        do {
            mindMaps = try await mindMapService.fetchMindMaps(token: token)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

struct MindMapListView: View {
    @StateObject private var viewModel = MindMapListViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAuthSheet = false
    
    var body: some View {
        NavigationView {
            Group {
                if !authViewModel.isAuthenticated {
                    VStack(spacing: 16) {
                        Text("Please sign in to view your mind maps")
                            .font(.headline)
                        Button("Sign In") {
                            showingAuthSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                } else if viewModel.isLoading {
                    ProgressView("Loading mind maps...")
                } else if let error = viewModel.error {
                    VStack {
                        Text("Error loading mind maps")
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.caption)
                        Button("Try Again") {
                            if let token = authViewModel.session?.accessToken {
                                Task {
                                    await viewModel.fetchMindMaps(token: token)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if viewModel.mindMaps.isEmpty {
                    VStack {
                        Text("No mind maps yet")
                            .font(.headline)
                        Text("Create your first mind map to get started!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.mindMaps) { mindMap in
                        NavigationLink(destination: SceneKitMindMapView()) {
                            VStack(alignment: .leading) {
                                Text(mindMap.name)
                                    .font(.headline)
                                Text(mindMap.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Created: \(mindMap.createdAt.formatted())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Mind Maps")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if authViewModel.isAuthenticated {
                        Button(action: {
                            // TODO: Add create mind map action
                        }) {
                            Label("Create Mind Map", systemImage: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAuthSheet) {
            TestAuthView()
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                showingAuthSheet = false  // Dismiss the sheet when auth succeeds
                if let token = authViewModel.session?.accessToken {
                    Task {
                        await viewModel.fetchMindMaps(token: token)
                    }
                }
            }
        }
    }
}

#Preview {
    MindMapListView()
        .environmentObject(AuthViewModel())
} 