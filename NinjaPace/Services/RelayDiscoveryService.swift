//
//  RelayDiscoveryService.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/21/26.
//

import Combine
import Foundation

@MainActor
final class RelayDiscoveryService: NSObject, ObservableObject, NetServiceBrowserDelegate, NetServiceDelegate {

    struct Relay: Identifiable, Equatable {
        let id: String
        let name: String
        let hostName: String
        let port: Int

        var address: String {
            "\(hostName):\(port)"
        }
    }

    @Published private(set) var discoveredRelays: [Relay] = []
    @Published private(set) var isSearching = false
    @Published private(set) var errorMessage: String?

    private let browser = NetServiceBrowser()
    private var resolvingServices: [String: NetService] = [:]

    override init() {
        super.init()
        browser.delegate = self
    }

    func startSearching() {
        guard !isSearching else { return }

        discoveredRelays = []
        errorMessage = nil
        isSearching = true

        browser.searchForServices(ofType: "_ninjapace._tcp.", inDomain: "local.")
    }

    func stopSearching() {
        browser.stop()
        resolvingServices.values.forEach { $0.stop() }
        resolvingServices.removeAll()
        isSearching = false
    }

    // MARK: - Browser

    nonisolated func netServiceBrowser(_: NetServiceBrowser, didFind service: NetService, moreComing _: Bool) {
        MainActor.assumeIsolated {
            service.delegate = self
            resolvingServices[service.name] = service
            service.resolve(withTimeout: 5)
        }
    }

    nonisolated func netServiceBrowser(_: NetServiceBrowser, didRemove service: NetService, moreComing _: Bool) {
        MainActor.assumeIsolated {
            discoveredRelays.removeAll { $0.name == service.name }
            resolvingServices[service.name] = nil
        }
    }

    nonisolated func netServiceBrowser(_: NetServiceBrowser, didNotSearch _: [String: NSNumber]) {
        MainActor.assumeIsolated {
            isSearching = false
            errorMessage = "NinjaPace couldn't search the local network."
        }
    }

    // MARK: - Resolution

    nonisolated func netServiceDidResolveAddress(_ sender: NetService) {
        MainActor.assumeIsolated {
            let name = sender.name
            let host = sender.hostName?.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            let port = sender.port

            resolvingServices[name] = nil

            guard let host, !host.isEmpty, port > 0 else { return }

            let relay = Relay(
                id: "\(name)-\(host)-\(port)",
                name: name,
                hostName: host,
                port: port
            )

            if let index = discoveredRelays.firstIndex(where: { $0.id == relay.id }) {
                discoveredRelays[index] = relay
            } else {
                discoveredRelays.append(relay)
            }

            discoveredRelays.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }

    nonisolated func netService(_ sender: NetService, didNotResolve _: [String: NSNumber]) {
        MainActor.assumeIsolated {
            resolvingServices[sender.name] = nil
        }
    }
}
