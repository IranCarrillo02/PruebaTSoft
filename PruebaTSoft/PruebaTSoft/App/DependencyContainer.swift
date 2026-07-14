import SwiftData

@MainActor
final class DependencyContainer {
    let modelContainer: ModelContainer
    let apiClient: APIClientProtocol
    let imageLoader: ImageLoading
    let pokemonRepository: PokemonRepositoryProtocol
    let fetchPokemonListUseCase: FetchPokemonListUseCaseProtocol
    let fetchPokemonDetailUseCase: FetchPokemonDetailUseCaseProtocol

    init() {
        do {
            modelContainer = try ModelContainer(for: CachedPokemon.self, CachedPokemonDetail.self)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }

        let apiClient = APIClient()
        let localDataSource = PokemonLocalDataSource(modelContainer: modelContainer)
        let repository = PokemonRepository(apiClient: apiClient, localDataSource: localDataSource)

        self.apiClient = apiClient
        self.imageLoader = ImageLoader()
        self.pokemonRepository = repository
        self.fetchPokemonListUseCase = FetchPokemonListUseCase(repository: repository)
        self.fetchPokemonDetailUseCase = FetchPokemonDetailUseCase(repository: repository)
    }

    func makePokemonListViewModel() -> PokemonListViewModel {
        PokemonListViewModel(fetchPokemonListUseCase: fetchPokemonListUseCase)
    }
}
