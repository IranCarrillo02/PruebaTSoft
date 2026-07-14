import Testing
@testable import PruebaTSoft

struct FetchPokemonDetailUseCaseTests {

    @Test func executeForwardsIDAndReturnsRepositoryResult() async throws {
        let repository = PokemonRepositoryMock()
        let expected = PokemonDetail(
            id: 1,
            name: "Bulbasaur",
            imageURL: nil,
            heightDecimeters: 7,
            weightHectograms: 69,
            baseExperience: 64,
            types: ["Grass", "Poison"],
            abilities: [PokemonAbility(name: "Overgrow", isHidden: false)],
            stats: [PokemonStat(name: "hp", baseValue: 45)]
        )
        repository.detailResult = .success(expected)
        let useCase = FetchPokemonDetailUseCase(repository: repository)

        let result = try await useCase.execute(id: 1)

        #expect(result == expected)
        #expect(repository.lastDetailRequest == 1)
    }

    @Test func executePropagatesRepositoryError() async throws {
        let repository = PokemonRepositoryMock()
        repository.detailResult = .failure(AppError.notFound)
        let useCase = FetchPokemonDetailUseCase(repository: repository)

        await #expect(throws: AppError.notFound) {
            try await useCase.execute(id: 999)
        }
    }
}
