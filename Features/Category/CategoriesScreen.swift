import SwiftUI
import Core
import Domain
import DesignSystem

struct CategoriesScreen: View {
    @State private var categories: [Domain.Category] = []
    @State private var newName = ""
    @State private var error: String?

    var body: some View {
        List {
            Section {
                HStack {
                    TextField(String(localized: "action_add_category"), text: $newName)
                    Button(String(localized: "action_add")) {
                        Task { await add() }
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            Section {
                ForEach(categories.filter { !$0.isSystemCategory }) { cat in
                    Text(cat.name)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await delete(cat) }
                            } label: {
                                Label(String(localized: "action_delete"), systemImage: "trash")
                            }
                        }
                }
            }
            if let error {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
        }
        .navigationTitle(String(localized: "categories"))
        .task { await load() }
    }

    private func load() async {
        guard let repo = AppContainer.shared.resolve(CategoryRepository.self) else { return }
        do {
            categories = try await GetCategories(repository: repo).await()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func add() async {
        guard let repo = AppContainer.shared.resolve(CategoryRepository.self) else { return }
        do {
            _ = try await CreateCategoryWithName(repository: repo).await(name: newName.trimmingCharacters(in: .whitespaces))
            newName = ""
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func delete(_ cat: Domain.Category) async {
        guard let repo = AppContainer.shared.resolve(CategoryRepository.self) else { return }
        do {
            try await DeleteCategory(repository: repo).await(id: cat.id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
