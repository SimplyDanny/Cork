//
//  Check if URL is Symlink.swift
//  Cork
//
//  Created by David Bureš on 25.02.2023.
//

import Foundation
import CorkShared

extension URL
{
    func isSymlink() -> Bool?
    {
        do
        {
            let fileAttributes: URLResourceValues = try resourceValues(forKeys: [.isSymbolicLinkKey])

            return fileAttributes.isSymbolicLink
        }
        catch let symlinkCheckingError
        {
            AppConstants.shared.logger.error("Error checking if \(self) is symlink: \(symlinkCheckingError)")

            return nil
        }
    }
}
