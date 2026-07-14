import Foundation
import Observation

@MainActor
@Observable
final class PokemonListViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case error(AppError)
    }

    private(set) var state: State = .idle
    private(set) var pokemons: [Pokemon] = []
    private(set) var isLoadingNextPage = false
    private(set) var canLoadMore = true

    var searchText: String = "" {
        didSet { scheduleSearch() }
    }
    private(set) var searchResults: [Pokemon] = []
    private(set) var isSearching = false

    private let fetchPokemonListUseCase: FetchPokemonListUseCaseProtocol
    private let searchPokemonUseCase: SearchPokemonUseCaseProtocol
    private let pageSize: Int
    private let searchDebounceNanoseconds: UInt64
    private var currentOffset = 0
    private static let paginationLookahead = 3
    /// Comfortably covers PokéAPI's ~1300 total Pokémon in a single call, so search
    /// works across everything, not just the pages the user has already scrolled through.
    private static let searchIndexLimit = 2000

    private var searchIndex: [Pokemon] = []
    private var hasLoadedSearchIndex = false
    private var searchDebounceTask: Task<Void, Never>?

    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(
        fetchPokemonListUseCase: FetchPokemonListUseCaseProtocol,
        searchPokemonUseCase: SearchPokemonUseCaseProtocol,
        pageSize: Int = 20,
        searchDebounceNanoseconds: UInt64 = 300_000_000
    ) {
        self.fetchPokemonListUseCase = fetchPokemonListUseCase
        self.searchPokemonUseCase = searchPokemonUseCase
        self.pageSize = pageSize
        self.searchDebounceNanoseconds = searchDebounceNanoseconds
    }

    func loadInitialPageIfNeeded() async {
        guard pokemons.isEmpty else { return }
        await loadFirstPage()
    }

    func refresh() async {
        await loadFirstPage()
    }

    func loadNextPageIfNeeded(currentItem pokemon: Pokemon) async {
        guard canLoadMore, !isLoadingNextPage else { return }
        guard let index = pokemons.firstIndex(where: { $0.id == pokemon.id }) else { return }
        let thresholdIndex = pokemons.count - Self.paginationLookahead
        guard index >= thresholdIndex else { return }
        await loadNextPage()
    }

    private func loadFirstPage() async {
        state = .loading
        do {
            let results = try await fetchPokemonListUseCase.execute(offset: 0, limit: pageSize)
            pokemons = results
            currentOffset = results.count
            canLoadMore = results.count == pageSize
            state = .loaded
        } catch {
            state = .error(Self.mapError(error))
        }
    }

    private func loadNextPage() async {
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }
        do {
            let results = try await fetchPokemonListUseCase.execute(offset: currentOffset, limit: pageSize)
            pokemons.append(contentsOf: results)
            currentOffset += results.count
            canLoadMore = results.count == pageSize
        } catch {
            canLoadMore = false
        }
    }

    private func scheduleSearch() {
        searchDebounceTask?.cancel()
        guard isSearchActive else {
            searchResults = []
            return
        }
        let debounce = searchDebounceNanoseconds
        searchDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: debounce)
            guard !Task.isCancelled else { return }
            await self?.performSearch()
        }
    }

    private func performSearch() async {
        isSearching = true
        defer { isSearching = false }

        if !hasLoadedSearchIndex {
            do {
                searchIndex = try await fetchPokemonListUseCase.execute(offset: 0, limit: Self.searchIndexLimit)
                hasLoadedSearchIndex = true
            } catch {
                searchResults = []
                return
            }
        }

        guard !Task.isCancelled else { return }
        searchResults = searchPokemonUseCase.execute(query: searchText, in: searchIndex)
    }

    private static func mapError(_ error: Error) -> AppError {
        (error as? AppError) ?? .unknown
    }
}
