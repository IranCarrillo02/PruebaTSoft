import Observation

@MainActor
@Observable
final class PokemonDetailViewModel {
    enum State: Equatable {
        case loading
        case loaded(PokemonDetail)
        case error(AppError)
    }

    private(set) var state: State = .loading

    let pokemon: Pokemon
    private let fetchPokemonDetailUseCase: FetchPokemonDetailUseCaseProtocol
    /// Bumped on every `load()` call. Guards against a rapid double-tap on "Reintentar"
    /// (or `loadIfNeeded()` and `retry()` overlapping) where an older, slower request
    /// resolves after a newer one and would otherwise clobber its result.
    private var loadGeneration = 0

    init(pokemon: Pokemon, fetchPokemonDetailUseCase: FetchPokemonDetailUseCaseProtocol) {
        self.pokemon = pokemon
        self.fetchPokemonDetailUseCase = fetchPokemonDetailUseCase
    }

    func loadIfNeeded() async {
        guard state == .loading else { return }
        await load()
    }

    func retry() async {
        state = .loading
        await load()
    }

    private func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        do {
            let detail = try await fetchPokemonDetailUseCase.execute(id: pokemon.id)
            guard generation == loadGeneration else { return }
            state = .loaded(detail)
        } catch {
            guard generation == loadGeneration else { return }
            state = .error((error as? AppError) ?? .unknown)
        }
    }
}
