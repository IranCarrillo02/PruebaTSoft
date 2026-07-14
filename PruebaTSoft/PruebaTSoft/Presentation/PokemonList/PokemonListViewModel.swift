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

    private let fetchPokemonListUseCase: FetchPokemonListUseCaseProtocol
    private let pageSize: Int
    private var currentOffset = 0
    private static let paginationLookahead = 3

    init(fetchPokemonListUseCase: FetchPokemonListUseCaseProtocol, pageSize: Int = 20) {
        self.fetchPokemonListUseCase = fetchPokemonListUseCase
        self.pageSize = pageSize
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

    private static func mapError(_ error: Error) -> AppError {
        (error as? AppError) ?? .unknown
    }
}
