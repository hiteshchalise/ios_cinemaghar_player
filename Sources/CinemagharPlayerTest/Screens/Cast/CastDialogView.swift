//
//  SwiftUIView.swift
//  CinemaGhar
//
//  Created by 12345 on 03/07/23.
//  Copyright © 2023 sunBi. All rights reserved.
//

import SwiftUI
import SmartView
import GoogleCast

enum CastState {
    /** No Cast session is established, and no Cast devices are available. */
    case castStateNoDevicesAvailable
    /** No Cast session is establishd, and Cast devices are available. */
    case castStateNotConnected
    /** A Cast session is being established. */
    case castStateConnecting
    /** A Cast session is established. */
    case castStateConnected
}



@available(iOS 14.0, *)
class CastViewModel: NSObject, ObservableObject, ServiceSearchDelegate, GCKDiscoveryManagerListener, GCKSessionManagerListener {
    
    @Published var devices: [Service] = []
    @Published var googleCastDevices: [GCKDevice] = []
    
    let discoveryManager: GCKDiscoveryManager = GCKCastContext.sharedInstance().discoveryManager
    let sessionManager: GCKSessionManager = GCKCastContext.sharedInstance().sessionManager
    let serviceSearch = Service.search()
    
    @Published var isGoogleCastSearching: Bool = false
    @Published var isSamsungCastSearching: Bool = false
    @Published var castState: CastState = CastState.castStateNoDevicesAvailable
    
    override init () {
        super.init()
        // The delegate is implemented as a weak reference
        serviceSearch.delegate = self
        serviceSearch.start()
        
        self.discoveryManager.stopDiscovery()
        self.discoveryManager.startDiscovery()
        self.discoveryManager.add(self)
        self.sessionManager.add(self)
        self.isGoogleCastSearching = true
    }
    
    // MARK: - ServiceSearchDelegate -
    func onServiceFound(_ service: Service) {
        // Update your UI by using the serviceDiscovery.services array
        if(!devices.contains(where: { device in
            device.name == service.name
        })){
            devices.append(service)
        }
        print("onServiceFound: ", service, devices)
        self.isSamsungCastSearching = false
        self.castState = CastState.castStateNotConnected
    }
    
    func onServiceLost(_ service: Service) {
        // Update your UI by using the serviceDiscovery.services array
        devices.removeAll(where: { device in
            device.name == service.name
        })
        print("onServiceLost: ",service, devices)
    }
    
    func onStop() {
        // The ServiceSearch will call this delegate method after stopping the search
        print("Search stopped")
        self.isSamsungCastSearching = false
    }
    
    func onStart() {
        // The ServiceSearch will call this delegate method after the search has started
        print("Search started")
        self.isSamsungCastSearching = true
    }
    
    // MARK: Google cast implementations
    
    func didInsert(_ device: GCKDevice, at index: UInt) {
        googleCastDevices.insert(device, at: Int(index))
        print("Cast Device Inserted \(String(describing: device.friendlyName))")
        self.isGoogleCastSearching = false
        self.castState = CastState.castStateNotConnected
    }
    
    func didRemove(_ device: GCKDevice, at index: UInt) {
        if(googleCastDevices.indices.contains(Int(index))){
            googleCastDevices.remove(at: Int(index))
        }
        print("Cast Device Removed \(String(describing: device.friendlyName))")
    }
    
    func didUpdate(_ device: GCKDevice, at index: UInt) {
        if(googleCastDevices.indices.contains(Int(index))){
            googleCastDevices[Int(index)] = device
        } else {
            googleCastDevices.append(device)
        }
        print("Cast Device Updated \(String(describing: device.friendlyName))")
        self.isGoogleCastSearching = false
        self.castState = CastState.castStateNotConnected
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKCastSession) {
        self.castState = CastState.castStateConnecting
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        self.castState = CastState.castStateNotConnected
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        self.castState = CastState.castStateConnected
    }
    
    func didStartDiscovery(forDeviceCategory deviceCategory: String) {
        isGoogleCastSearching = true
    }
    
    func stopSearch() {
        self.serviceSearch.stop()
        self.discoveryManager.stopDiscovery()
    }
    
}

struct CastDialogView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var castViewModel: CastViewModel = CastViewModel()
    
    private var serviceTapHandler: (Service) -> ()
    
    init(serviceTapHandler: @escaping (Service) -> ()) {
        self.serviceTapHandler = serviceTapHandler
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
            
            List {
                HStack{
                    Text("Cast Devices").fontWeight(.bold)
                    Spacer()
                    if(castViewModel.isGoogleCastSearching || castViewModel.isSamsungCastSearching){
                        ProgressView()
                    }
                }
                
                switch(castViewModel.castState) {
                case CastState.castStateNoDevicesAvailable:
                    Text("No cast devices available.")
                case CastState.castStateNotConnected:
                    ForEach(castViewModel.devices, id: \.name) { item in
                        Button {
                            serviceTapHandler(item)
                            castViewModel.castState = CastState.castStateConnecting
                            castViewModel.stopSearch()
                        } label: {
                            Text(item.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(castViewModel.googleCastDevices, id: \.friendlyName) { item in
                        Button {
                            castViewModel.sessionManager.startSession(with: item)
                            castViewModel.stopSearch()
                        } label: {
                            Text(item.friendlyName ?? "Chromecast device")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                case CastState.castStateConnecting:
                    HStack{
                        Text("Connecting...")
                        Spacer()
                        ProgressView()
                    }
                case CastState.castStateConnected:
                    HStack{
                        Text("Connected...")
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .background(.gray)
            .frame(width: 400, height: 300)
            .cornerRadius(10)
            .shadow(radius: 10)
        }
        .preferredColorScheme(.dark)
    }
}
