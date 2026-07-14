import Testing
@testable import PruebaTSoft

struct FetchPokemonListUseCaseTests {

    @Test func executeForwardsOffsetAndLimitAndReturnsRepositoryResult() async throws {
        let repository = PokemonRepositoryMock()
        let expected = [Pokemon(id: 1, name: "Bulbasaur", imageURL: nil)]
        repository.listResult = .success(expected)
        let useCase = FetchPokemonListUseCase(repository: repository)

        let result = try await useCase.execute(offset: 20, limit: 20)

        #expect(result == expected)
        #expect(repository.lastListRequest?.offset == 20)
        #expect(repository.lastListRequest?.limit == 20)
    }

    @Test func executePropagatesRepositoryError() async throws {
        let repository = PokemonRepositoryMock()
        repository.listResult = .failure(AppError.noConnection)
        let useCase = FetchPokemonListUseCase(repository: repository)

        await #expect(throws: AppError.noConnection) {
            try await useCase.execute(offset: 0, limit: 20)
        }
    }
}
