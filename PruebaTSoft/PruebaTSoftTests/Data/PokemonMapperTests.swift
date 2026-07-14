import Foundation
import Testing
@testable import PruebaTSoft

struct PokemonMapperTests {

    @Test func extractIDReadsTrailingNumericPathSegment() {
        #expect(PokemonMapper.extractID(from: "https://pokeapi.co/api/v2/pokemon/25/") == 25)
        #expect(PokemonMapper.extractID(from: "https://pokeapi.co/api/v2/pokemon/25") == 25)
        #expect(PokemonMapper.extractID(from: "not-a-url") == nil)
    }

    @Test func spriteURLIsBuiltFromID() {
        let expected = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"
        let url = PokemonMapper.spriteURL(for: 25)
        #expect(url?.absoluteString == expected)
    }

    @Test func listItemMapsToDomainUsingSpriteURLNotDetailCall() throws {
        let dto = PokemonListItemDTO(name: "pikachu", url: "https://pokeapi.co/api/v2/pokemon/25/")

        let pokemon = try #require(PokemonMapper.toDomain(listItem: dto))

        #expect(pokemon.id == 25)
        #expect(pokemon.name == "Pikachu")
        #expect(pokemon.imageURL?.absoluteString.contains("25.png") == true)
    }

    @Test func listItemWithMalformedURLMapsToNil() {
        let dto = PokemonListItemDTO(name: "missingno", url: "not-a-url")
        #expect(PokemonMapper.toDomain(listItem: dto) == nil)
    }

    @Test func detailDTOMapsAllFieldsToDomain() {
        let dto = PokemonDetailDTO(
            id: 25,
            name: "pikachu",
            height: 4,
            weight: 60,
            baseExperience: 112,
            sprites: PokemonSpritesDTO(frontDefault: "https://example.com/pikachu.png"),
            types: [PokemonTypeSlotDTO(type: NamedResourceDTO(name: "electric"))],
            abilities: [PokemonAbilitySlotDTO(ability: NamedResourceDTO(name: "static"), isHidden: false)],
            stats: [PokemonStatSlotDTO(baseStat: 35, stat: NamedResourceDTO(name: "hp"))]
        )

        let detail = PokemonMapper.toDomain(detail: dto)

        #expect(detail.id == 25)
        #expect(detail.name == "Pikachu")
        #expect(detail.imageURL?.absoluteString == "https://example.com/pikachu.png")
        #expect(detail.heightInMeters == 0.4)
        #expect(detail.weightInKilograms == 6.0)
        #expect(detail.baseExperience == 112)
        #expect(detail.types == ["Electric"])
        #expect(detail.abilities == [PokemonAbility(name: "Static", isHidden: false)])
        #expect(detail.stats == [PokemonStat(name: "hp", baseValue: 35)])
    }

    @Test func detailDTOWithoutSpriteFallsBackToConstructedSpriteURL() {
        let dto = PokemonDetailDTO(
            id: 25,
            name: "pikachu",
            height: 4,
            weight: 60,
            baseExperience: nil,
            sprites: PokemonSpritesDTO(frontDefault: nil),
            types: [],
            abilities: [],
            stats: []
        )

        let detail = PokemonMapper.toDomain(detail: dto)

        #expect(detail.imageURL?.absoluteString.contains("25.png") == true)
    }

    @Test func pokemonRoundTripsThroughSwiftDataCacheModel() {
        let pokemon = Pokemon(id: 1, name: "Bulbasaur", imageURL: URL(string: "https://example.com/1.png"))

        let cached = PokemonMapper.toCached(pokemon, order: 5)
        let roundTripped = PokemonMapper.toDomain(cached: cached)

        #expect(cached.order == 5)
        #expect(roundTripped == pokemon)
    }

    @Test func pokemonDetailRoundTripsThroughSwiftDataCacheModel() {
        let detail = PokemonDetail(
            id: 1,
            name: "Bulbasaur",
            imageURL: URL(string: "https://example.com/1.png"),
            heightDecimeters: 7,
            weightHectograms: 69,
            baseExperience: 64,
            types: ["Grass", "Poison"],
            abilities: [PokemonAbility(name: "Overgrow", isHidden: false)],
            stats: [PokemonStat(name: "hp", baseValue: 45)]
        )

        let cached = PokemonMapper.toCached(detail)
        let roundTripped = PokemonMapper.toDomain(cached: cached)

        #expect(roundTripped == detail)
    }
}
