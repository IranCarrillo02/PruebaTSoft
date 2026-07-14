import SwiftUI

struct PokemonListView: View {
    @State private var viewModel: PokemonListViewModel
    private let imageLoader: ImageLoading

    init(viewModel: PokemonListViewModel, imageLoader: ImageLoading) {
        _viewModel = State(initialValue: viewModel)
        self.imageLoader = imageLoader
    }

    var body: some View {
        content
            .navigationTitle("Pokédex")
            .task {
                await viewModel.loadInitialPageIfNeeded()
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.pokemons.isEmpty {
            switch viewModel.state {
            case .idle, .loading:
                SkeletonListView()
            case let .error(error):
                ErrorStateView(message: error.errorDescription ?? "") {
                    Task { await viewModel.refresh() }
                }
            case .loaded:
                EmptyStateView()
            }
        } else {
            list
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.pokemons) { pokemon in
                PokemonRowView(pokemon: pokemon, imageLoader: imageLoader)
                    .onAppear {
                        Task { await viewModel.loadNextPageIfNeeded(currentItem: pokemon) }
                    }
            }

            if viewModel.isLoadingNextPage {
                HStack {
                    Spacer()
                    ProgressView()
                        .accessibilityLabel("Cargando más Pokémon")
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
    }
}
