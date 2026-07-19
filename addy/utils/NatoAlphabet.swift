
import Foundation

class NatoAlphabet {
    struct NatoItem {
        let character: Character
        let word: String
        let phonetic: String
    }

    static func getWord(_ character: Character) -> NatoItem {
        switch character.lowercased() {
        case "a":
            return NatoItem(character: character, word: "Alfa", phonetic: "AL FAH")
        case "b":
            return NatoItem(character: character, word: "Bravo", phonetic: "BRAH VOH")
        case "c":
            return NatoItem(character: character, word: "Charlie", phonetic: "CHAR LEE")
        case "d":
            return NatoItem(character: character, word: "Delta", phonetic: "DELL TAH")
        case "e":
            return NatoItem(character: character, word: "Echo", phonetic: "ECK OH")
        case "f":
            return NatoItem(character: character, word: "Foxtrot", phonetic: "FOKS TROT")
        case "g":
            return NatoItem(character: character, word: "Golf", phonetic: "GOLF")
        case "h":
            return NatoItem(character: character, word: "Hotel", phonetic: "HOH TELL")
        case "i":
            return NatoItem(character: character, word: "India", phonetic: "IN DEE AH")
        case "j":
            return NatoItem(character: character, word: "Juliett", phonetic: "JEW LEE ETT")
        case "k":
            return NatoItem(character: character, word: "Kilo", phonetic: "KEY LOH")
        case "l":
            return NatoItem(character: character, word: "Lima", phonetic: "LEE MAH")
        case "m":
            return NatoItem(character: character, word: "Mike", phonetic: "MIKE")
        case "n":
            return NatoItem(character: character, word: "November", phonetic: "NO VEM BER")
        case "o":
            return NatoItem(character: character, word: "Oscar", phonetic: "OSS CAH")
        case "p":
            return NatoItem(character: character, word: "Papa", phonetic: "PAH PAH")
        case "q":
            return NatoItem(character: character, word: "Quebec", phonetic: "KEH BECK")
        case "r":
            return NatoItem(character: character, word: "Romeo", phonetic: "ROW ME OH")
        case "s":
            return NatoItem(character: character, word: "Sierra", phonetic: "SEE AIRRAH")
        case "t":
            return NatoItem(character: character, word: "Tango", phonetic: "TANG GO")
        case "u":
            return NatoItem(character: character, word: "Uniform", phonetic: "YOU NEE FORM")
        case "v":
            return NatoItem(character: character, word: "Victor", phonetic: "VIK TAH")
        case "w":
            return NatoItem(character: character, word: "Whiskey", phonetic: "WISS KEY")
        case "x":
            return NatoItem(character: character, word: "X-ray", phonetic: "ECKS RAY")
        case "y":
            return NatoItem(character: character, word: "Yankee", phonetic: "YANG KEY")
        case "z":
            return NatoItem(character: character, word: "Zulu", phonetic: "ZOO LOO")
        case "0":
            return NatoItem(character: character, word: "Zero", phonetic: "ZE RO")
        case "1":
            return NatoItem(character: character, word: "One", phonetic: "WUN")
        case "2":
            return NatoItem(character: character, word: "Two", phonetic: "TOO")
        case "3":
            return NatoItem(character: character, word: "Three", phonetic: "TREE")
        case "4":
            return NatoItem(character: character, word: "Four", phonetic: "FOW ER")
        case "5":
            return NatoItem(character: character, word: "Five", phonetic: "FIFE")
        case "6":
            return NatoItem(character: character, word: "Six", phonetic: "SIX")
        case "7":
            return NatoItem(character: character, word: "Seven", phonetic: "SEV EN")
        case "8":
            return NatoItem(character: character, word: "Eight", phonetic: "AIT")
        case "9":
            return NatoItem(character: character, word: "Nine", phonetic: "NIN ER")
        case ".":
            return NatoItem(character: character, word: "Dot", phonetic: "DOT")
        case "@":
            return NatoItem(character: character, word: "At", phonetic: "AT")
        case "-":
            return NatoItem(character: character, word: "Dash", phonetic: "DASH")
        case "_":
            return NatoItem(character: character, word: "Underscore", phonetic: "UNDERSCORE")
        default:
            return NatoItem(character: character, word: String(character), phonetic: "")
        }
    }
}
