//
//  PaintColorLibrary.swift
//  TaulbeePainting
//
//  Curated selection of popular real colors across Sherwin-Williams,
//  Benjamin Moore, and PPG. Hex values are close approximations for
//  on-screen preview and AI color guidance.
//

import Foundation

nonisolated enum PaintColorLibrary {
    static let all: [PaintColor] = sherwinWilliams + benjaminMoore + ppg

    static func colors(brand: PaintBrand?, family: ColorFamily?, query: String) -> [PaintColor] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return all.filter { color in
            (brand == nil || color.brand == brand)
                && (family == nil || color.family == family)
                && (trimmed.isEmpty
                    || color.name.localizedCaseInsensitiveContains(trimmed)
                    || color.code.localizedCaseInsensitiveContains(trimmed))
        }
    }

    // MARK: - Sherwin-Williams

    static let sherwinWilliams: [PaintColor] = [
        .init(brand: .sherwinWilliams, name: "Pure White", code: "7005", hex: "EDECE6", family: .whites),
        .init(brand: .sherwinWilliams, name: "Alabaster", code: "7008", hex: "EDEAE0", family: .whites),
        .init(brand: .sherwinWilliams, name: "High Reflective White", code: "7757", hex: "F7F6F2", family: .whites),
        .init(brand: .sherwinWilliams, name: "Snowbound", code: "7004", hex: "EDEBE6", family: .whites),
        .init(brand: .sherwinWilliams, name: "Dover White", code: "6385", hex: "EDE3CE", family: .neutrals),
        .init(brand: .sherwinWilliams, name: "Accessible Beige", code: "7036", hex: "D1C7B8", family: .neutrals),
        .init(brand: .sherwinWilliams, name: "Kilim Beige", code: "6106", hex: "C9B59E", family: .neutrals),
        .init(brand: .sherwinWilliams, name: "Agreeable Gray", code: "7029", hex: "D1CBC1", family: .neutrals),
        .init(brand: .sherwinWilliams, name: "Repose Gray", code: "7015", hex: "C9C5BD", family: .grays),
        .init(brand: .sherwinWilliams, name: "Mindful Gray", code: "7016", hex: "BCB7AE", family: .grays),
        .init(brand: .sherwinWilliams, name: "Gray Screen", code: "7071", hex: "B6B7B3", family: .grays),
        .init(brand: .sherwinWilliams, name: "Dorian Gray", code: "7017", hex: "A39E94", family: .grays),
        .init(brand: .sherwinWilliams, name: "Sea Salt", code: "6204", hex: "CDD5CA", family: .greens),
        .init(brand: .sherwinWilliams, name: "Oyster Bay", code: "6206", hex: "A4ABA0", family: .greens),
        .init(brand: .sherwinWilliams, name: "Evergreen Fog", code: "9130", hex: "95998D", family: .greens),
        .init(brand: .sherwinWilliams, name: "Pewter Green", code: "6208", hex: "5F6A5E", family: .greens),
        .init(brand: .sherwinWilliams, name: "Rainwashed", code: "6211", hex: "C5D2C7", family: .greens),
        .init(brand: .sherwinWilliams, name: "Misty", code: "6232", hex: "C7D0CC", family: .blues),
        .init(brand: .sherwinWilliams, name: "Sleepy Blue", code: "6225", hex: "AEC0BE", family: .blues),
        .init(brand: .sherwinWilliams, name: "Naval", code: "6244", hex: "2F3A4A", family: .blues),
        .init(brand: .sherwinWilliams, name: "In the Navy", code: "9178", hex: "303B47", family: .blues),
        .init(brand: .sherwinWilliams, name: "Distance", code: "6243", hex: "53636B", family: .blues),
        .init(brand: .sherwinWilliams, name: "Iron Ore", code: "7069", hex: "434341", family: .darks),
        .init(brand: .sherwinWilliams, name: "Tricorn Black", code: "6258", hex: "2F2F30", family: .darks),
        .init(brand: .sherwinWilliams, name: "Urbane Bronze", code: "7048", hex: "54504A", family: .darks),
        .init(brand: .sherwinWilliams, name: "Caviar", code: "6990", hex: "2B2B2B", family: .darks),
        .init(brand: .sherwinWilliams, name: "Cavern Clay", code: "7701", hex: "AD6A4E", family: .warm),
        .init(brand: .sherwinWilliams, name: "Roycroft Copper Red", code: "2839", hex: "7E4B3A", family: .warm),
        .init(brand: .sherwinWilliams, name: "Carnival", code: "6892", hex: "E29A3B", family: .warm),
        .init(brand: .sherwinWilliams, name: "Latte", code: "6108", hex: "B49A7E", family: .earth),
        .init(brand: .sherwinWilliams, name: "Macadamia", code: "6142", hex: "C7AE8E", family: .earth),
        .init(brand: .sherwinWilliams, name: "Rookwood Red", code: "2802", hex: "6E3A35", family: .warm),
    ]

    // MARK: - Benjamin Moore

    static let benjaminMoore: [PaintColor] = [
        .init(brand: .benjaminMoore, name: "Simply White", code: "OC-117", hex: "F4F2E7", family: .whites),
        .init(brand: .benjaminMoore, name: "White Dove", code: "OC-17", hex: "F0EDE1", family: .whites),
        .init(brand: .benjaminMoore, name: "Cloud White", code: "OC-130", hex: "F2EFE6", family: .whites),
        .init(brand: .benjaminMoore, name: "Chantilly Lace", code: "OC-65", hex: "F4F4EF", family: .whites),
        .init(brand: .benjaminMoore, name: "Swiss Coffee", code: "OC-45", hex: "ECE7D8", family: .neutrals),
        .init(brand: .benjaminMoore, name: "Revere Pewter", code: "HC-172", hex: "CCC3B4", family: .neutrals),
        .init(brand: .benjaminMoore, name: "Shaker Beige", code: "HC-45", hex: "C9B49B", family: .neutrals),
        .init(brand: .benjaminMoore, name: "Manchester Tan", code: "HC-81", hex: "D2C3A9", family: .neutrals),
        .init(brand: .benjaminMoore, name: "Classic Gray", code: "OC-23", hex: "E5E0D6", family: .grays),
        .init(brand: .benjaminMoore, name: "Gray Owl", code: "OC-52", hex: "D2D2C8", family: .grays),
        .init(brand: .benjaminMoore, name: "Stonington Gray", code: "HC-170", hex: "C6C8C4", family: .grays),
        .init(brand: .benjaminMoore, name: "Chelsea Gray", code: "HC-168", hex: "898680", family: .grays),
        .init(brand: .benjaminMoore, name: "Kendall Charcoal", code: "HC-166", hex: "6A6A60", family: .darks),
        .init(brand: .benjaminMoore, name: "Wrought Iron", code: "2124-10", hex: "41474C", family: .darks),
        .init(brand: .benjaminMoore, name: "Soot", code: "2129-20", hex: "353B40", family: .darks),
        .init(brand: .benjaminMoore, name: "Black Beauty", code: "2128-10", hex: "2C2F33", family: .darks),
        .init(brand: .benjaminMoore, name: "Hale Navy", code: "HC-154", hex: "444B52", family: .blues),
        .init(brand: .benjaminMoore, name: "Van Deusen Blue", code: "HC-156", hex: "47596A", family: .blues),
        .init(brand: .benjaminMoore, name: "Newburyport Blue", code: "HC-155", hex: "3F4A57", family: .blues),
        .init(brand: .benjaminMoore, name: "Palladian Blue", code: "HC-144", hex: "BBCBC0", family: .blues),
        .init(brand: .benjaminMoore, name: "Wythe Blue", code: "HC-143", hex: "A7BBA8", family: .greens),
        .init(brand: .benjaminMoore, name: "Saybrook Sage", code: "HC-114", hex: "9AA383", family: .greens),
        .init(brand: .benjaminMoore, name: "October Mist", code: "1495", hex: "A6A88F", family: .greens),
        .init(brand: .benjaminMoore, name: "Guilford Green", code: "HC-116", hex: "ABAE93", family: .greens),
        .init(brand: .benjaminMoore, name: "Caliente", code: "AF-290", hex: "9C342E", family: .warm),
        .init(brand: .benjaminMoore, name: "Raspberry Blush", code: "2008-30", hex: "C75545", family: .warm),
        .init(brand: .benjaminMoore, name: "Hawthorne Yellow", code: "HC-4", hex: "E4C77E", family: .warm),
        .init(brand: .benjaminMoore, name: "Pale Oak", code: "OC-20", hex: "DAD2C5", family: .neutrals),
        .init(brand: .benjaminMoore, name: "Edgecomb Gray", code: "HC-173", hex: "D3CBBC", family: .neutrals),
        .init(brand: .benjaminMoore, name: "Cinnamon", code: "2174-20", hex: "8E4B33", family: .earth),
    ]

    // MARK: - PPG

    static let ppg: [PaintColor] = [
        .init(brand: .ppg, name: "Delicate White", code: "PPG1001-1", hex: "EFEDE6", family: .whites),
        .init(brand: .ppg, name: "Commercial White", code: "PPG1025-1", hex: "F1EFE6", family: .whites),
        .init(brand: .ppg, name: "Gypsum", code: "PPG1097-3", hex: "E4DCCB", family: .whites),
        .init(brand: .ppg, name: "Antique White", code: "PPG14-20", hex: "E8DDC6", family: .neutrals),
        .init(brand: .ppg, name: "Toasty Gray", code: "PPG1024-4", hex: "C3B7A6", family: .neutrals),
        .init(brand: .ppg, name: "Stonehenge Greige", code: "PPG1024-3", hex: "CFC4B2", family: .neutrals),
        .init(brand: .ppg, name: "Whirlwind", code: "PPG1011-3", hex: "CBCAC4", family: .grays),
        .init(brand: .ppg, name: "Gray Stone", code: "PPG1009-4", hex: "B3B1A8", family: .grays),
        .init(brand: .ppg, name: "Knight's Armor", code: "PPG1011-6", hex: "84857F", family: .grays),
        .init(brand: .ppg, name: "Dover Gray", code: "PPG1001-4", hex: "ADA9A0", family: .grays),
        .init(brand: .ppg, name: "Mostly Metal", code: "PPG1009-5", hex: "8E8C85", family: .grays),
        .init(brand: .ppg, name: "Antique Silver", code: "PPG1011-5", hex: "9A9A92", family: .grays),
        .init(brand: .ppg, name: "Dark Night", code: "PPG1043-7", hex: "37414B", family: .blues),
        .init(brand: .ppg, name: "Adventure", code: "PPG1159-7", hex: "32414A", family: .blues),
        .init(brand: .ppg, name: "Cyberspace", code: "PPG1011-7", hex: "474A4D", family: .darks),
        .init(brand: .ppg, name: "Black Magic", code: "PPG1001-7", hex: "2C2C2E", family: .darks),
        .init(brand: .ppg, name: "Black Flame", code: "PPG1043-7B", hex: "2A2D31", family: .darks),
        .init(brand: .ppg, name: "Penniman Blue", code: "CW-615", hex: "5A6E74", family: .blues),
        .init(brand: .ppg, name: "Mountain Stream", code: "PPG1149-4", hex: "8FA6A4", family: .blues),
        .init(brand: .ppg, name: "Sea Pine", code: "PPG1145-5", hex: "6F8079", family: .greens),
        .init(brand: .ppg, name: "Clover Field", code: "PPG1126-5", hex: "7C8666", family: .greens),
        .init(brand: .ppg, name: "Pine Whisper", code: "PPG1133-5", hex: "8C9281", family: .greens),
        .init(brand: .ppg, name: "Reseda Green", code: "PPG1123-4", hex: "A6AA8C", family: .greens),
        .init(brand: .ppg, name: "Hot Sauce", code: "PPG1188-7", hex: "9B3A2E", family: .warm),
        .init(brand: .ppg, name: "Spiced Cider", code: "PPG1199-6", hex: "A85F39", family: .warm),
        .init(brand: .ppg, name: "Glowing Firelight", code: "PPG1200-6", hex: "C06A3D", family: .warm),
        .init(brand: .ppg, name: "Wild Rice", code: "PPG1097-4", hex: "D6C8A8", family: .earth),
        .init(brand: .ppg, name: "Toffee Crunch", code: "PPG1085-6", hex: "8B6A4B", family: .earth),
        .init(brand: .ppg, name: "Chocolate Bar", code: "PPG1075-7", hex: "5A4636", family: .earth),
        .init(brand: .ppg, name: "Ground Nutmeg", code: "PPG1071-6", hex: "7A5C46", family: .earth),
    ]
}
