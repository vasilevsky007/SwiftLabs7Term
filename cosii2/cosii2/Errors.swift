//
//  Errors.swift
//  cosii1
//
//  Created by Alex on 27.09.23.
//

import Foundation

struct LocalizedAlertError: LocalizedError {
    let underlyingError: LocalizedError
    var errorDescription: String? {
        underlyingError.errorDescription
    }
    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }

    init?(error: Error?) {
        guard let localizedError = error as? LocalizedError else { return nil }
        underlyingError = localizedError
    }
}

public enum MyError: LocalizedError {
    case openNilURL
    public var errorDescription: String? {
        switch self {
        case .openNilURL:
            return "Убедитесь, что выбрали изображение перед нажатием кнопки Открыть"
        }
    }
}
