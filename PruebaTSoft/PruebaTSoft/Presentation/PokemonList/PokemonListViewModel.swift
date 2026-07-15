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

    /// Bumped on every `loadFirstPage()` (initial load or refresh). A `loadNextPage()` call
    /// that was already in flight when a refresh restarted the list captures the generation
    /// current at its start and discards its result if that generation is no longer current —
    /// otherwise a slow pagination response resolving after a refresh could silently append
    /// stale data onto (or clobber) the freshly reloaded list. See docs/decisions.md ADR-014.
    private var listGeneration = 0
    /// Same idea as `listGeneration`, scoped to search: a slow search-index fetch or filter
    /// resolving after a newer keystroke's search must not overwrite the newer results.
    private var searchGeneration = 0

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
        listGeneration += 1
        let generation = listGeneration
        state = .loading
        do {
            let results = try await fetchPokemonListUseCase.execute(offset: 0, limit: pageSize)
            guard generation == listGeneration else { return }
            pokemons = results
            currentOffset = results.count
            canLoadMore = results.count == pageSize
            state = .loaded
        } catch {
            guard generation == listGeneration else { return }
            state = .error(Self.mapError(error))
        }
    }

    private func loadNextPage() async {
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }
        let generation = listGeneration
        do {
            let results = try await fetchPokemonListUseCase.execute(offset: currentOffset, limit: pageSize)
            guard generation == listGeneration else { return }
            pokemons.append(contentsOf: results)
            currentOffset += results.count
            canLoadMore = results.count == pageSize
        } catch {
            guard generation == listGeneration else { return }
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

    /// Exposed (internal, not part of the public UI-facing API) so tests can deterministically
    /// await the in-flight debounced search via `@testable import`, instead of polling flags or
    /// sleeping a fixed duration that can be too short under heavy parallel test load.
    func waitForPendingSearchToFinish() async {
        await searchDebounceTask?.value
    }

    private func performSearch() async {
        searchGeneration += 1
        let generation = searchGeneration
        isSearching = true
        defer {
            // Only the still-current generation should clear the flag — otherwise a stale
            // search finishing after a newer one started could flip `isSearching` back to
            // false while that newer search is still genuinely in flight.
            if generation == searchGeneration { isSearching = false }
        }

        if !hasLoadedSearchIndex {
            do {
                let index = try await fetchPokemonListUseCase.execute(offset: 0, limit: Self.searchIndexLimit)
                guard generation == searchGeneration else { return }
                searchIndex = index
                hasLoadedSearchIndex = true
            } catch {
                guard generation == searchGeneration else { return }
                searchResults = []
                return
            }
        }

        guard generation == searchGeneration else { return }
        searchResults = searchPokemonUseCase.execute(query: searchText, in: searchIndex)
    }

    private static func mapError(_ error: Error) -> AppError {
        (error as? AppError) ?? .unknown
    }
}
