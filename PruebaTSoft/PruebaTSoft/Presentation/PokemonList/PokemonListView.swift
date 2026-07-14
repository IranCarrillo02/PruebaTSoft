import SwiftUI

struct PokemonListView: View {
    @State private var viewModel: PokemonListViewModel
    private let imageLoader: ImageLoading
    private let fetchPokemonDetailUseCase: FetchPokemonDetailUseCaseProtocol

    init(
        viewModel: PokemonListViewModel,
        imageLoader: ImageLoading,
        fetchPokemonDetailUseCase: FetchPokemonDetailUseCaseProtocol
    ) {
        _viewModel = State(initialValue: viewModel)
        self.imageLoader = imageLoader
        self.fetchPokemonDetailUseCase = fetchPokemonDetailUseCase
    }

    var body: some View {
        content
            .navigationTitle("Pokédex")
            .searchable(
                text: Binding(get: { viewModel.searchText }, set: { viewModel.searchText = $0 }),
                prompt: "Buscar Pokémon"
            )
            .navigationDestination(for: Pokemon.self) { pokemon in
                PokemonDetailView(
                    viewModel: PokemonDetailViewModel(
                        pokemon: pokemon,
                        fetchPokemonDetailUseCase: fetchPokemonDetailUseCase
                    ),
                    imageLoader: imageLoader
                )
            }
            .task {
                await viewModel.loadInitialPageIfNeeded()
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isSearchActive {
            searchResultsContent
        } else if viewModel.pokemons.isEmpty {
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

    @ViewBuilder
    private var searchResultsContent: some View {
        if viewModel.searchResults.isEmpty {
            if viewModel.isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyStateView(message: "No se encontraron Pokémon para \"\(viewModel.searchText)\".")
            }
        } else {
            List(viewModel.searchResults) { pokemon in
                NavigationLink(value: pokemon) {
                    PokemonRowView(pokemon: pokemon, imageLoader: imageLoader)
                }
            }
            .listStyle(.plain)
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.pokemons) { pokemon in
                NavigationLink(value: pokemon) {
                    PokemonRowView(pokemon: pokemon, imageLoader: imageLoader)
                }
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
