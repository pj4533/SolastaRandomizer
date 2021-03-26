import Vapor

struct DungeonContent: Content {
    var raw: String?
    var difficulty: String?
	var level: Int?
}
