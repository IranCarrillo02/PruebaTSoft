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
        do {
            let detail = try await fetchPokemonDetailUseCase.execute(id: pokemon.id)
            state = .loaded(detail)
        } catch {
            state = .error((error as? AppError) ?? .unknown)
        }
    }
}
