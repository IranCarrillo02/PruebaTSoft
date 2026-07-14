import Testing
@testable import PruebaTSoft

@MainActor
struct PokemonListViewModelTests {

    /// 1ms instead of the production 300ms debounce, so search tests stay fast and deterministic.
    private static let testDebounceNanoseconds: UInt64 = 1_000_000

    private func makePokemons(_ range: Range<Int>) -> [Pokemon] {
        range.map { Pokemon(id: $0, name: "Pokemon \($0)", imageURL: nil) }
    }

    private func makeViewModel(
        fetchUseCase: FetchPokemonListUseCaseMock,
        searchUseCase: SearchPokemonUseCaseProtocol = SearchPokemonUseCase(),
        pageSize: Int = 5
    ) -> PokemonListViewModel {
        PokemonListViewModel(
            fetchPokemonListUseCase: fetchUseCase,
            searchPokemonUseCase: searchUseCase,
            pageSize: pageSize,
            searchDebounceNanoseconds: Self.testDebounceNanoseconds
        )
    }

    @Test func loadInitialPageIfNeededPopulatesPokemonsAndAllowsMoreWhenFullPageReturned() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByOffset[0] = .success(makePokemons(0..<5))
        let viewModel = makeViewModel(fetchUseCase: useCase)

        await viewModel.loadInitialPageIfNeeded()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.pokemons.count == 5)
        #expect(viewModel.canLoadMore == true)
    }

    @Test func loadInitialPageIfNeededSetsCanLoadMoreFalseWhenPartialPageReturned() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByOffset[0] = .success(makePokemons(0..<3))
        let viewModel = makeViewModel(fetchUseCase: useCase)

        await viewModel.loadInitialPageIfNeeded()

        #expect(viewModel.canLoadMore == false)
    }

    @Test func loadInitialPageIfNeededDoesNothingWhenAlreadyLoaded() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByOffset[0] = .success(makePokemons(0..<5))
        let viewModel = makeViewModel(fetchUseCase: useCase)
        await viewModel.loadInitialPageIfNeeded()

        await viewModel.loadInitialPageIfNeeded()

        #expect(useCase.requestedOffsets == [0])
    }

    @Test func loadInitialPageIfNeededSetsErrorStateOnFailure() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByOffset[0] = .failure(AppError.noConnection)
        let viewModel = makeViewModel(fetchUseCase: useCase)

        await viewModel.loadInitialPageIfNeeded()

        #expect(viewModel.state == .error(.noConnection))
        #expect(viewModel.pokemons.isEmpty)
    }

    @Test func refreshReloadsFromOffsetZeroEvenWhenAlreadyLoaded() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByOffset[0] = .success(makePokemons(0..<5))
        let viewModel = makeViewModel(fetchUseCase: useCase)
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
        let viewModel = makeViewModel(fetchUseCase: useCase)
        await viewModel.loadInitialPageIfNeeded()

        await viewModel.loadNextPageIfNeeded(currentItem: firstPage.last!)

        #expect(viewModel.pokemons.count == 10)
        #expect(useCase.requestedOffsets == [0, 5])
    }

    @Test func loadNextPageIfNeededDoesNothingWhenNotNearTheEnd() async {
        let useCase = FetchPokemonListUseCaseMock()
        let firstPage = makePokemons(0..<5)
        useCase.resultsByOffset[0] = .success(firstPage)
        let viewModel = makeViewModel(fetchUseCase: useCase)
        await viewModel.loadInitialPageIfNeeded()

        await viewModel.loadNextPageIfNeeded(currentItem: firstPage[0])

        #expect(viewModel.pokemons.count == 5)
        #expect(useCase.requestedOffsets == [0])
    }

    @Test func loadNextPageIfNeededDoesNothingWhenCanLoadMoreIsFalse() async {
        let useCase = FetchPokemonListUseCaseMock()
        let firstPage = makePokemons(0..<3)
        useCase.resultsByOffset[0] = .success(firstPage)
        let viewModel = makeViewModel(fetchUseCase: useCase)
        await viewModel.loadInitialPageIfNeeded()
        #expect(viewModel.canLoadMore == false)

        await viewModel.loadNextPageIfNeeded(currentItem: firstPage.last!)

        #expect(useCase.requestedOffsets == [0])
    }

    // MARK: - Search

    private func waitForDebounce() async {
        try? await Task.sleep(nanoseconds: Self.testDebounceNanoseconds * 5)
    }

    @Test func settingSearchTextPopulatesResultsFromTheFullIndex() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByLimit[2000] = .success([
            Pokemon(id: 4, name: "Charmander", imageURL: nil),
            Pokemon(id: 6, name: "Charizard", imageURL: nil),
            Pokemon(id: 1, name: "Bulbasaur", imageURL: nil)
        ])
        let viewModel = makeViewModel(fetchUseCase: useCase)

        viewModel.searchText = "char"
        await waitForDebounce()

        #expect(viewModel.searchResults.map(\.name) == ["Charmander", "Charizard"])
        #expect(viewModel.isSearchActive == true)
    }

    @Test func clearingSearchTextClearsResultsImmediately() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByLimit[2000] = .success([Pokemon(id: 4, name: "Charmander", imageURL: nil)])
        let viewModel = makeViewModel(fetchUseCase: useCase)
        viewModel.searchText = "char"
        await waitForDebounce()
        #expect(viewModel.searchResults.isEmpty == false)

        viewModel.searchText = ""

        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.isSearchActive == false)
    }

    @Test func searchIndexIsOnlyFetchedOnceAcrossMultipleSearches() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByLimit[2000] = .success([
            Pokemon(id: 4, name: "Charmander", imageURL: nil),
            Pokemon(id: 1, name: "Bulbasaur", imageURL: nil)
        ])
        let viewModel = makeViewModel(fetchUseCase: useCase)

        viewModel.searchText = "char"
        await waitForDebounce()
        viewModel.searchText = "bulba"
        await waitForDebounce()

        #expect(viewModel.searchResults.map(\.name) == ["Bulbasaur"])
        #expect(useCase.requestedCalls.filter { $0.limit == 2000 }.count == 1)
    }

    @Test func searchReturnsEmptyResultsWhenTheIndexFetchFails() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByLimit[2000] = .failure(AppError.noConnection)
        let viewModel = makeViewModel(fetchUseCase: useCase)

        viewModel.searchText = "char"
        await waitForDebounce()

        #expect(viewModel.searchResults.isEmpty)
    }
}
