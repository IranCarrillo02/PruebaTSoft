import Testing
@testable import PruebaTSoft

@MainActor
struct PokemonDetailViewModelTests {

    private func makeDetail(id: Int) -> PokemonDetail {
        PokemonDetail(
            id: id,
            name: "Bulbasaur",
            imageURL: nil,
            heightDecimeters: 7,
            weightHectograms: 69,
            baseExperience: 64,
            types: ["Grass", "Poison"],
            abilities: [PokemonAbility(name: "Overgrow", isHidden: false)],
            stats: [PokemonStat(name: "hp", baseValue: 45)]
        )
    }

    @Test func loadIfNeededTransitionsFromLoadingToLoaded() async {
        let useCase = FetchPokemonDetailUseCaseMock()
        let detail = makeDetail(id: 1)
        useCase.result = .success(detail)
        let pokemon = Pokemon(id: 1, name: "Bulbasaur", imageURL: nil)
        let viewModel = PokemonDetailViewModel(pokemon: pokemon, fetchPokemonDetailUseCase: useCase)

        #expect(viewModel.state == .loading)
        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .loaded(detail))
        #expect(useCase.requestedIDs == [1])
    }

    @Test func loadIfNeededDoesNothingAfterAlreadyLoaded() async {
        let useCase = FetchPokemonDetailUseCaseMock()
        useCase.result = .success(makeDetail(id: 1))
        let pokemon = Pokemon(id: 1, name: "Bulbasaur", imageURL: nil)
        let viewModel = PokemonDetailViewModel(pokemon: pokemon, fetchPokemonDetailUseCase: useCase)
        await viewModel.loadIfNeeded()

        await viewModel.loadIfNeeded()

        #expect(useCase.requestedIDs == [1])
    }

    @Test func loadIfNeededSetsErrorStateOnFailure() async {
        let useCase = FetchPokemonDetailUseCaseMock()
        useCase.result = .failure(AppError.noConnection)
        let pokemon = Pokemon(id: 1, name: "Bulbasaur", imageURL: nil)
        let viewModel = PokemonDetailViewModel(pokemon: pokemon, fetchPokemonDetailUseCase: useCase)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .error(.noConnection))
    }

    @Test func retryReloadsAfterAPreviousFailure() async {
        let useCase = FetchPokemonDetailUseCaseMock()
        useCase.result = .failure(AppError.noConnection)
        let pokemon = Pokemon(id: 1, name: "Bulbasaur", imageURL: nil)
        let viewModel = PokemonDetailViewModel(pokemon: pokemon, fetchPokemonDetailUseCase: useCase)
        await viewModel.loadIfNeeded()
        #expect(viewModel.state == .error(.noConnection))

        let detail = makeDetail(id: 1)
        useCase.result = .success(detail)
        await viewModel.retry()

        #expect(viewModel.state == .loaded(detail))
        #expect(useCase.requestedIDs == [1, 1])
    }

    @Test func rapidRetryDiscardsAStaleEarlierResultThatResolvesAfterwards() async {
        let useCase = FetchPokemonDetailUseCaseMock()
        useCase.blockedCallIndex = 1 // the first call (from loadIfNeeded) resolves last
        useCase.resultsByCallIndex[1] = .failure(AppError.noConnection)
        let detail = makeDetail(id: 1)
        useCase.resultsByCallIndex[2] = .success(detail)
        let pokemon = Pokemon(id: 1, name: "Bulbasaur", imageURL: nil)
        let viewModel = PokemonDetailViewModel(pokemon: pokemon, fetchPokemonDetailUseCase: useCase)

        async let firstLoad: Void = viewModel.loadIfNeeded()
        try? await Task.sleep(nanoseconds: 5_000_000) // let the first call register and block

        await viewModel.retry() // second call is not blocked and succeeds immediately
        #expect(viewModel.state == .loaded(detail))

        useCase.openGate() // release the stale first call
        await firstLoad
        try? await Task.sleep(nanoseconds: 5_000_000)

        #expect(viewModel.state == .loaded(detail)) // unchanged by the stale, later completion
    }
}
