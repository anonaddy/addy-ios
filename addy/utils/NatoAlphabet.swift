
import Foundation

class NatoAlphabet {
    struct NatoItem {
        let character: Character
        let word: String
    }

    static func getWord(_ character: Character) -> NatoItem {
        switch character.lowercased() {
        case "a":
            return NatoItem(character: character, word: "Alfa")
        case "b":
            return NatoItem(character: character, word: "Bravo")
        case "c":
            return NatoItem(character: character, word: "Charlie")
        case "d":
            return NatoItem(character: character, word: "Delta")
        case "e":
            return NatoItem(character: character, word: "Echo")
        case "f":
            return NatoItem(character: character, word: "Foxtrot")
        case "g":
            return NatoItem(character: character, word: "Golf")
        case "h":
            return NatoItem(character: character, word: "Hotel")
        case "i":
            return NatoItem(character: character, word: "India")
        case "j":
            return NatoItem(character: character, word: "Juliett")
        case "k":
            return NatoItem(character: character, word: "Kilo")
        case "l":
            return NatoItem(character: character, word: "Lima")
        case "m":
            return NatoItem(character: character, word: "Mike")
        case "n":
            return NatoItem(character: character, word: "November")
        case "o":
            return NatoItem(character: character, word: "Oscar")
        case "p":
            return NatoItem(character: character, word: "Papa")
        case "q":
            return NatoItem(character: character, word: "Quebec")
        case "r":
            return NatoItem(character: character, word: "Romeo")
        case "s":
            return NatoItem(character: character, word: "Sierra")
        case "t":
            return NatoItem(character: character, word: "Tango")
        case "u":
            return NatoItem(character: character, word: "Uniform")
        case "v":
            return NatoItem(character: character, word: "Victor")
        case "w":
            return NatoItem(character: character, word: "Whiskey")
        case "x":
            return NatoItem(character: character, word: "X-ray")
        case "y":
            return NatoItem(character: character, word: "Yankee")
        case "z":
            return NatoItem(character: character, word: "Zulu")
        case "0":
            return NatoItem(character: character, word: "Zero")
        case "1":
            return NatoItem(character: character, word: "One")
        case "2":
            return NatoItem(character: character, word: "Two")
        case "3":
            return NatoItem(character: character, word: "Three")
        case "4":
            return NatoItem(character: character, word: "Four")
        case "5":
            return NatoItem(character: character, word: "Five")
        case "6":
            return NatoItem(character: character, word: "Six")
        case "7":
            return NatoItem(character: character, word: "Seven")
        case "8":
            return NatoItem(character: character, word: "Eight")
        case "9":
            return NatoItem(character: character, word: "Nine")
        case ".":
            return NatoItem(character: character, word: "Dot")
        case "@":
            return NatoItem(character: character, word: "At")
        case "-":
            return NatoItem(character: character, word: "Dash")
        case "_":
            return NatoItem(character: character, word: "Underscore")
        default:
            return NatoItem(character: character, word: String(character))
        }
    }
}
