import Testing
@testable import PruebaTSoft

@MainActor
struct PokemonListViewModelTests {

    private func makePokemons(_ range: Range<Int>) -> [Pokemon] {
        range.map { Pokemon(id: $0, name: "Pokemon \($0)", imageURL: nil) }
    }

    @Test func loadInitialPageIfNeededPopulatesPokemonsAndAllowsMoreWhenFullPageReturned() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByOffset[0] = .success(makePokemons(0..<5))
        let viewModel = PokemonListViewModel(fetchPokemonListUseCase: useCase, pageSize: 5)

        await viewModel.loadInitialPageIfNeeded()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.pokemons.count == 5)
        #expect(viewModel.canLoadMore == true)
    }

    @Test func loadInitialPageIfNeededSetsCanLoadMoreFalseWhenPartialPageReturned() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByOffset[0] = .success(makePokemons(0..<3))
        let viewModel = PokemonListViewModel(fetchPokemonListUseCase: useCase, pageSize: 5)

        await viewModel.loadInitialPageIfNeeded()

        #expect(viewModel.canLoadMore == false)
    }

    @Test func loadInitialPageIfNeededDoesNothingWhenAlreadyLoaded() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByOffset[0] = .success(makePokemons(0..<5))
        let viewModel = PokemonListViewModel(fetchPokemonListUseCase: useCase, pageSize: 5)
        await viewModel.loadInitialPageIfNeeded()

        await viewModel.loadInitialPageIfNeeded()

        #expect(useCase.requestedOffsets == [0])
    }

    @Test func loadInitialPageIfNeededSetsErrorStateOnFailure() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByOffset[0] = .failure(AppError.noConnection)
        let viewModel = PokemonListViewModel(fetchPokemonListUseCase: useCase, pageSize: 5)

        await viewModel.loadInitialPageIfNeeded()

        #expect(viewModel.state == .error(.noConnection))
        #expect(viewModel.pokemons.isEmpty)
    }

    @Test func refreshReloadsFromOffsetZeroEvenWhenAlreadyLoaded() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByOffset[0] = .success(makePokemons(0..<5))
        let viewModel = PokemonListViewModel(fetchPokemonListUseCase: useCase, pageSize: 5)
        await viewModel.loadInitialPageIfNeeded()

        await viewModel.refresh()

        #expect(useCase.requestedOffsets == [0, 0])
        #expect(viewModel.pokemons.count == 5)
    }

    @Test func loadNextPageIfNeededAppendsResultsWhenNearTheEnd() async {
        let useCase = FetchPokemonListUseCaseMock()
        let firstPage = makePokemons(0..<5)
        useCase.resultsByOffset[0] = .success(firstPage)
        useCase.resultsByOffset[5] = .success(makePokemons(5..<10))
        let viewModel = PokemonListViewModel(fetchPokemonListUseCase: useCase, pageSize: 5)
        await viewModel.loadInitialPageIfNeeded()

        await viewModel.loadNextPageIfNeeded(currentItem: firstPage.last!)

        #expect(viewModel.pokemons.count == 10)
        #expect(useCase.requestedOffsets == [0, 5])
    }

    @Test func loadNextPageIfNeededDoesNothingWhenNotNearTheEnd() async {
        let useCase = FetchPokemonListUseCaseMock()
        let firstPage = makePokemons(0..<5)
        useCase.resultsByOffset[0] = .success(firstPage)
        let viewModel = PokemonListViewModel(fetchPokemonListUseCase: useCase, pageSize: 5)
        await viewModel.loadInitialPageIfNeeded()

        await viewModel.loadNextPageIfNeeded(currentItem: firstPage[0])

        #expect(viewModel.pokemons.count == 5)
        #expect(useCase.requestedOffsets == [0])
    }

    @Test func loadNextPageIfNeededDoesNothingWhenCanLoadMoreIsFalse() async {
        let useCase = FetchPokemonListUseCaseMock()
        let firstPage = makePokemons(0..<3)
        useCase.resultsByOffset[0] = .success(firstPage)
        let viewModel = PokemonListViewModel(fetchPokemonListUseCase: useCase, pageSize: 5)
        await viewModel.loadInitialPageIfNeeded()
        #expect(viewModel.canLoadMore == false)

        await viewModel.loadNextPageIfNeeded(currentItem: firstPage.last!)

        #expect(useCase.requestedOffsets == [0])
    }
}
