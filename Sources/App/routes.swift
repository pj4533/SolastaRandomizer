import Vapor
import SolastaKit
import Leaf

func routes(_ app: Application) throws {
    app.get { req in
        req.view.render("index", [
            "title": "SolastaRandomizer",
            "body": "Solasta Dungeon Randomizer",
            "level": "5",
            "difficulty": "Hard"
        ])
    }

    app.get("randomize") { req in
        req.view.render("index", [
            "title": "SolastaRandomizer",
            "body": "Solasta Dungeon Randomizer",
            "level": "5",
            "difficulty": "Hard"
        ])
    }

    app.on(.POST, "randomize", body: .collect(maxSize: "4mb")) { req -> EventLoopFuture<Vapor.View> in
        let dungeonContent = try req.content.decode(DungeonContent.self)
        let data = dungeonContent.raw?.data(using: .utf8) ?? Data()
        var randomized : String = ""
        
        let level = dungeonContent.level ?? 5
        let difficulty: Difficulty = Difficulty(rawValue: dungeonContent.difficulty?.lowercased() ?? "hard") ?? .hard
        
        let decoder = JSONDecoder()
        var dungeon = try decoder.decode(Dungeon.self, from: data)

        let datasource = EncounterDataSource()
        for index in 0..<(dungeon.userRooms?.count ?? 0) {
            if let numberOfEnemies = dungeon.userRooms?[index].userGadgets?.filter({$0.gadgetBlueprintName == "MonsterM"}).count, numberOfEnemies > 0 {
                let creatureLabels = datasource.getEncounter(withNumberCreatures: numberOfEnemies, forAverageLvl: level, withDifficulty: difficulty)
                
                var i = 0
                // I dont like this -- I usually use classes, but with structs its all values. Prob a better syntax for this, but I am going fast.
                for mindex in 0..<(dungeon.userRooms?[index].userGadgets?.count ?? 0) {
                    if dungeon.userRooms?[index].userGadgets?[mindex].gadgetBlueprintName == "MonsterM" {
                        for jindex in 0..<(dungeon.userRooms?[index].userGadgets?[mindex].parameterValues?.count ?? 0) {
                            if dungeon.userRooms?[index].userGadgets?[mindex].parameterValues?[jindex].gadgetParameterDescriptionName == "Creature" {
                                if i < creatureLabels.count {
                                    dungeon.userRooms?[index].userGadgets?[mindex].parameterValues?[jindex].stringValue = creatureLabels[i]
                                    i = i + 1
                                } else {
                                    dungeon.userRooms?[index].userGadgets?[mindex].parameterValues?[jindex].stringValue = ""
                                }
                            }
                        }
                    }
                }
            }
        }
        
        dungeon.startLevelMin = level
        dungeon.startLevelMax = level

        // Serializing dungeon file out
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let dungeonJSONData = try? encoder.encode(dungeon) {
            randomized = String(data: dungeonJSONData, encoding: .utf8) ?? ""
        } else {
            print("Error processing dungeon file")
        }

         return req.view.render("index", [
            "title": "SolastaRandomizer",
            "body": "Solasta Dungeon Randomizer",
            "raw": dungeonContent.raw ?? "",
            "randomized": randomized,
            "level": "\(level)",
            "difficulty": "\(difficulty.rawValue.capitalized)"
        ])
    }

}
