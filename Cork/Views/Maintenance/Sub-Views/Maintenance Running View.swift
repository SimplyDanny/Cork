//
//  Maintenance Running View.swift
//  Cork
//
//  Created by David Bureš on 04.10.2023.
//

import SwiftUI
import CorkShared

struct MaintenanceRunningView: View
{
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var brewData: BrewDataStorage
    @EnvironmentObject var navigationManager: MaintenanceView.MaintenanceNavigationManager

    @State var currentMaintenanceStepText: LocalizedStringKey = "maintenance.step.initial"

    let shouldUninstallOrphans: Bool
    let shouldPurgeCache: Bool
    let shouldDeleteDownloads: Bool
    let shouldPerformHealthCheck: Bool

    @Binding var numberOfOrphansRemoved: Int
    @Binding var packagesHoldingBackCachePurge: [String]
    @Binding var reclaimedSpaceAfterCachePurge: Int
    @Binding var brewHealthCheckFoundNoProblems: Bool

    var body: some View
    {
        ProgressView
        {
            Text(currentMaintenanceStepText)
                .task(priority: .userInitiated)
                {
                    if shouldUninstallOrphans
                    {
                        currentMaintenanceStepText = "maintenance.step.removing-orphans"

                        do
                        {
                            numberOfOrphansRemoved = try await uninstallOrphansUtility()
                        }
                        catch let orphanUninstallatioError
                        {
                            AppConstants.shared.logger.error("Orphan uninstallation error: \(orphanUninstallatioError.localizedDescription, privacy: .public))")
                        }
                    }
                    else
                    {
                        AppConstants.shared.logger.info("Will not uninstall orphans")
                    }

                    if shouldPurgeCache
                    {
                        currentMaintenanceStepText = "maintenance.step.purging-cache"

                        do
                        {
                            packagesHoldingBackCachePurge = try await purgeHomebrewCacheUtility()

                            AppConstants.shared.logger.info("Length of array of packages that are holding back cache purge: \(packagesHoldingBackCachePurge.count)")
                        }
                        catch let homebrewCachePurgingError
                        {
                            AppConstants.shared.logger.error("Homebrew cache purging error: \(homebrewCachePurgingError.localizedDescription, privacy: .public))")
                        }
                    }
                    else
                    {
                        AppConstants.shared.logger.info("Will not purge cache")
                    }

                    if shouldDeleteDownloads
                    {
                        AppConstants.shared.logger.info("Will delete downloads")

                        currentMaintenanceStepText = "maintenance.step.deleting-cached-downloads"

                        deleteCachedDownloads()

                        /// I have to assign the original value of the appState variable to a different variable, because when it updates at the end of the process, I don't want it to update in the result overview
                        reclaimedSpaceAfterCachePurge = Int(appState.cachedDownloadsFolderSize)

                        await appState.loadCachedDownloadedPackages()
                        appState.assignPackageTypeToCachedDownloads(brewData: brewData)
                    }
                    else
                    {
                        AppConstants.shared.logger.info("Will not delete downloads")
                    }

                    if shouldPerformHealthCheck
                    {
                        currentMaintenanceStepText = "maintenance.step.running-health-check"

                        do
                        {
                            let healthCheckOutput: TerminalOutput = try await performBrewHealthCheck()
                            AppConstants.shared.logger.log("Health check output:\nStandard output: \(healthCheckOutput.standardOutput)\nStandard error: \(healthCheckOutput.standardError)")

                            brewHealthCheckFoundNoProblems = true
                        }
                        catch let healthCheckError
                        {
                            AppConstants.shared.logger.error("Health check error: \(healthCheckError, privacy: .public)")
                        }
                    }
                    else
                    {
                        AppConstants.shared.logger.info("Will not perform health check")
                    }

                    navigationManager.navigate(to: .finished)
                }
        }
        .padding()
        .frame(width: 200)
    }
}
