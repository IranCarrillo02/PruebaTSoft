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

    @Test func refreshDiscardsAStalePaginationResultThatResolvesAfterwards() async throws {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByOffset[0] = .success(makePokemons(0..<5))
        // Distinguishable "wrong" ids stand in for stale page-2 data fetched before the refresh.
        useCase.resultsByOffset[5] = .success(makePokemons(100..<105))
        useCase.gate(offset: 5) // hold the pagination call open until we explicitly release it
        let viewModel = makeViewModel(fetchUseCase: useCase)
        await viewModel.loadInitialPageIfNeeded()
        let lastItem = try #require(viewModel.pokemons.last)

        async let pagination: Void = viewModel.loadNextPageIfNeeded(currentItem: lastItem)
        try? await Task.sleep(nanoseconds: 5_000_000) // let pagination start and reach the gate
        await viewModel.refresh() // completes fully while pagination is still gated
        useCase.openGate(for: 5) // only now let the stale pagination call resolve
        await pagination

        #expect(viewModel.pokemons.map(\.id) == Array(0..<5))
    }

    // MARK: - Search

    /// For tests that deliberately inspect state *while* a search is gated mid-flight (so
    /// waiting for `isSearching` to settle would defeat the point): polls until the mock has
    /// registered the expected number of calls instead of sleeping a fixed, load-sensitive duration.
    private func waitUntil(
        _ useCase: FetchPokemonListUseCaseMock,
        hasRequestedCallCount expectedCount: Int,
        timeoutNanoseconds: UInt64 = 2_000_000_000
    ) async {
        let deadline = ContinuousClock.now.advanced(by: .nanoseconds(Int64(timeoutNanoseconds)))
        while useCase.requestedCalls.count < expectedCount, ContinuousClock.now < deadline {
            await Task.yield()
        }
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
        await viewModel.waitForPendingSearchToFinish()

        #expect(viewModel.searchResults.map(\.name) == ["Charmander", "Charizard"])
        #expect(viewModel.isSearchActive == true)
    }

    @Test func clearingSearchTextClearsResultsImmediately() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByLimit[2000] = .success([Pokemon(id: 4, name: "Charmander", imageURL: nil)])
        let viewModel = makeViewModel(fetchUseCase: useCase)
        viewModel.searchText = "char"
        await viewModel.waitForPendingSearchToFinish()
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
        await viewModel.waitForPendingSearchToFinish()
        viewModel.searchText = "bulba"
        await viewModel.waitForPendingSearchToFinish()

        #expect(viewModel.searchResults.map(\.name) == ["Bulbasaur"])
        #expect(useCase.requestedCalls.filter { $0.limit == 2000 }.count == 1)
    }

    @Test func staleSearchCannotClobberANewerSearchsResultsOrLoadingFlag() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByLimit[2000] = .success([
            Pokemon(id: 4, name: "Charmander", imageURL: nil),
            Pokemon(id: 1, name: "Bulbasaur", imageURL: nil)
        ])
        useCase.gate(offset: 0)
        let viewModel = makeViewModel(fetchUseCase: useCase)

        viewModel.searchText = "char"
        await waitUntil(useCase, hasRequestedCallCount: 1) // generation 1 registers, blocks on the gate

        viewModel.searchText = "bulba"
        await waitUntil(useCase, hasRequestedCallCount: 2) // generation 2 registers, blocks on the gate
        #expect(viewModel.isSearching == true)

        useCase.openGate(for: 0, callsToAllow: 1) // release the stale generation 1 call first
        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(viewModel.isSearching == true) // generation 2 is still genuinely in flight
        #expect(viewModel.searchResults.isEmpty)

        useCase.openGate(for: 0, callsToAllow: 1) // now release generation 2
        await viewModel.waitForPendingSearchToFinish()

        #expect(viewModel.searchResults.map(\.name) == ["Bulbasaur"])
        #expect(viewModel.isSearching == false)
    }

    @Test func searchReturnsEmptyResultsWhenTheIndexFetchFails() async {
        let useCase = FetchPokemonListUseCaseMock()
        useCase.resultsByLimit[2000] = .failure(AppError.noConnection)
        let viewModel = makeViewModel(fetchUseCase: useCase)

        viewModel.searchText = "char"
        await viewModel.waitForPendingSearchToFinish()

        #expect(viewModel.searchResults.isEmpty)
    }
}
