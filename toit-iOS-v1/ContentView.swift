//
//  ContentView.swift
//  toit-iOS-v1
//
//  Created by Michael Melville on 08/01/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var showingAuthTest = false

    var body: some View {
        TabView {
            // Home Tab
            VStack {
                Text("Let's get a round toit!")
                    .font(.largeTitle)
                    .padding()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            

            
            // Add SceneKit Mind Map Tab
            SceneKitMindMapView()
                .tabItem {
                    Label("SceneKit", systemImage: "brain.head.profile")
                }
            
  
            
            // Original Items List Tab
            NavigationSplitView {
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showingAuthTest = true }) {
                            Label("Test Auth", systemImage: "key.fill")
                        }
                    }
                }
            } detail: {
                Text("Select an item")
            }
            .tabItem {
                Label("Items", systemImage: "list.bullet")
            }
        }
        .sheet(isPresented: $showingAuthTest) {
            TestAuthView()
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
