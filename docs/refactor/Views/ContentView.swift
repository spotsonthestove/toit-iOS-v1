//
//  ContentView.swift
//  try-toit
//
//  Created by Michael Melville on 07/10/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
<<<<<<< HEAD

    var body: some View {
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
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
=======
    @State private var newItemText = ""

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item: \(item.text) at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.text)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                
                // Add text input field
                HStack {
                    TextField("New item text", text: $newItemText)
                    Button("Add") {
                        addItem()
                    }
                }
                .padding()
            }
            .navigationTitle("Items")
>>>>>>> 339e479 (Initial Commit)
        }
    }

    private func addItem() {
        withAnimation {
<<<<<<< HEAD
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
=======
            let newItem = Item(timestamp: Date(), text: newItemText)
            modelContext.insert(newItem)
            newItemText = "" // Clear the input field
>>>>>>> 339e479 (Initial Commit)
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
