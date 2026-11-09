//
//  NinjaPaceBonjourBrowser.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/21/26.
//

import Combine
import Foundation
import Network

@MainActor
final class NinjaPaceBonjourBrowser: NSObject, ObservableObject, NetServiceDelegate {

    struct DiscoveredRelay: Identifiable, Equatable {
        let id: String
        let name: String
        let host: String
        let port: Int

        var address: String {
            "\(host):\(port)"
        }
    }

    private struct ResolvingService {
        let id: ObjectIdentifier
        let service: NetService
    }

    @Published private(set) var discoveredRelays: [DiscoveredRelay] = []
    @Published private(set) var isBrowsing = false
    @Published private(set) var errorMessage: String?

    private var browser: NWBrowser?
    private var resolvingServices: [String: ResolvingService] = [:]
    private var advertisedServiceNames: Set<String> = []

    // MARK: - Browsing

    func startBrowsing() {
        guard browser == nil else { return }

        errorMessage = nil

        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true

        let browser = NWBrowser(
            for: .bonjour(type: "_ninjapace._tcp", domain: "local."),
            using: parameters
        )

        browser.stateUpdateHandler = { [weak self, weak browser] state in
            guard let owner = self, let browser else { return }

            Task { @MainActor [owner, browser] in
                guard owner.browser === browser else { return }

                switch state {
                case .ready:
                    owner.isBrowsing = true
                    owner.errorMessage = nil

                case .waiting(let error):
                    owner.isBrowsing = false
                    owner.errorMessage = Self.browserMessage(for: error)

                case .failed(let error):
                    owner.isBrowsing = false
                    owner.errorMessage = Self.browserMessage(for: error)
                    owner.discoveredRelays = []
                    owner.stopBrowsing()

                case .cancelled:
                    owner.isBrowsing = false

                default:
                    break
                }
            }
        }

        browser.browseResultsChangedHandler = { [weak self, weak browser] results, _ in
            guard let owner = self, let browser else { return }

            let snapshot = results

            Task { @MainActor [owner, browser, snapshot] in
                guard owner.browser === browser else { return }
                owner.handleResults(snapshot)
            }
        }

        self.browser = browser
        browser.start(queue: .global(qos: .userInitiated))
    }

    func stopBrowsing() {
        browser?.cancel()
        browser = nil

        resolvingServices.values.forEach { $0.service.stop() }
        resolvingServices.removeAll()
        advertisedServiceNames.removeAll()

        isBrowsing = false
    }

    // MARK: - Results

    private func handleResults(_ results: Set<NWBrowser.Result>) {
        let services = results.compactMap { result -> (name: String, type: String, domain: String)? in
            guard case let .service(name, type, domain, _) = result.endpoint else { return nil }
            return (name, type, domain)
        }

        let currentNames = Set(services.map { $0.name })
        advertisedServiceNames = currentNames

        // Remove Macs that are no longer being advertised.
        discoveredRelays.removeAll {
            !currentNames.contains($0.name)
        }

        // Cancel resolutions for Macs that disappeared before resolving.
        let removedResolutionNames = resolvingServices.keys.filter {
            !currentNames.contains($0)
        }

        for name in removedResolutionNames {
            resolvingServices[name]?.service.stop()
            resolvingServices[name] = nil
        }

        for service in services {
            resolve(name: service.name, type: service.type, domain: service.domain)
        }
    }

    // MARK: - Bonjour Resolution

    private func resolve(name: String, type: String, domain: String) {
        guard resolvingServices[name] == nil else { return }

        let service = NetService(domain: domain, type: type, name: name)
        service.delegate = self

        resolvingServices[name] = ResolvingService(
            id: ObjectIdentifier(service),
            service: service
        )

        service.resolve(withTimeout: 5)
    }

    // MARK: - NetServiceDelegate

    nonisolated func netServiceDidResolveAddress(_ sender: NetService) {
        let name = sender.name
        let host = sender.hostName
        let port = sender.port
        let resolutionID = ObjectIdentifier(sender)

        Task { @MainActor in
            guard self.resolvingServices[name]?.id == resolutionID else {
                return
            }

            defer {
                self.resolvingServices[name] = nil
            }

            guard
                self.advertisedServiceNames.contains(name),
                let host,
                port > 0
            else {
                return
            }

            let cleanedHost = Self.cleanBonjourHost(host)

            let relay = DiscoveredRelay(
                id: "\(name)-\(cleanedHost)-\(port)",
                name: name,
                host: cleanedHost,
                port: port
            )

            self.insertOrReplace(relay)
        }
    }

    nonisolated func netService(_ sender: NetService, didNotResolve _: [String: NSNumber]) {
        let name = sender.name
        let resolutionID = ObjectIdentifier(sender)

        Task { @MainActor in
            guard self.resolvingServices[name]?.id == resolutionID else {
                return
            }

            self.resolvingServices[name] = nil
        }
    }

    // MARK: - Storage

    private func insertOrReplace(_ relay: DiscoveredRelay) {
        // Replace by service name so DHCP address changes update the existing Mac.
        if let index = discoveredRelays.firstIndex(where: { $0.name == relay.name }) {
            discoveredRelays[index] = relay
        } else {
            discoveredRelays.append(relay)
        }

        discoveredRelays.sort {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    // MARK: - Helpers

    nonisolated private static func cleanBonjourHost(_ host: String) -> String {
        host.hasSuffix(".") ? String(host.dropLast()) : host
    }

    nonisolated private static func browserMessage(for error: NWError) -> String {
        let description = error.localizedDescription

        if description.contains("-65555") ||
            description.localizedCaseInsensitiveContains("NoAuth") {
            return """
            Local Network access is disabled. \
            Enable it in Settings → Privacy & Security → \
            Local Network → NinjaPace.
            """
        }

        return """
        NinjaPace couldn’t search for nearby Macs. \
        Make sure your iPhone and Mac are on the same \
        local network and try again.
        """
    }
}
